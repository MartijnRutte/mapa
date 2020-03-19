
import java.util.*;
import java.util.logging.*;
import java.io.*;
import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.*;

/**


*/
public class JclStep {

	private Logger LOGGER = null;
	private TheCLI CLI = null;
	private UUID uuid = UUID.randomUUID();
	private String myName = null;
	private String fileName = null;
	private String procName = null;
	private String stepName = null;
	private int line = -1;
	private KeywordOrSymbolicWrapper procExecuted = null;
	private KeywordOrSymbolicWrapper pgmExecuted = null;
	private Proc proc = null;
	private Boolean inProc = null;
	private JCLParser.JclStepContext jclStepCtx = null;
	private JCLParser.ExecStatementContext execStmtCtx = null;
	private JCLParser.ExecPgmStatementContext execPgmStmtCtx = null;
	private JCLParser.ExecProcStatementContext execProcStmtCtx = null;
	private List<JCLParser.DdStatementAmalgamationContext> ddStmtAmlgnCtxs = null;
	private ArrayList<SetSymbolValue> setSym = new ArrayList<>();
	private ArrayList<DdStatementAmalgamation> ddStatements = new ArrayList<>();

	public JclStep(JCLParser.JclStepContext jclStepCtx, String fileName, String procName, Logger LOGGER, TheCLI CLI) {
		this.jclStepCtx = jclStepCtx;
		this.fileName = fileName;
		this.procName = procName;
		this.LOGGER = LOGGER;
		this.CLI = CLI;
		this.inProc = !(procName == null);
		this.initialize();
		this.LOGGER.finer(this.myName + " " + this.stepName + " instantiated from " + this.fileName);

	}

	private void initialize() {
		this.myName = this.getClass().getName();
		this.execStmtCtx = this.jclStepCtx.execStatement();
		this.execPgmStmtCtx = this.execStmtCtx.execPgmStatement();
		this.execProcStmtCtx = this.execStmtCtx.execProcStatement();
		this.ddStmtAmlgnCtxs = this.jclStepCtx.ddStatementAmalgamation();
		
		if (this.isExecProc() && this.isExecPgm()) {
			this.LOGGER.severe(this.myName + " both execPgmStmtCtx and ExecProcStmtCtx are not null");
		} else if (!this.isExecProc() && !this.isExecPgm()) {
			this.LOGGER.severe(this.myName + " both execPgmStmtCtx and ExecProcStmtCtx are null");
		}

		if (this.isExecPgm()) {
			this.line = this.execPgmStmtCtx.EXEC().getSymbol().getLine();
			if (this.execPgmStmtCtx.stepName() == null) {
			} else {
				this.stepName = this.execPgmStmtCtx.stepName().NAME_FIELD().getSymbol().getText();
			}
			this.pgmExecuted = new KeywordOrSymbolicWrapper(this.execPgmStmtCtx.keywordOrSymbolic(), this.procName);
		} else {
			this.line = this.execProcStmtCtx.EXEC().getSymbol().getLine();
			if (this.execProcStmtCtx.stepName() == null) {
			} else {
				this.stepName = this.execProcStmtCtx.stepName().NAME_FIELD().getSymbol().getText();
			}
			this.procExecuted = new KeywordOrSymbolicWrapper(this.execProcStmtCtx.keywordOrSymbolic(), this.procName);
			for (JCLParser.ExecProcParmContext epp: this.execProcStmtCtx.execProcParm()) {
				this.setSym.add(new SetSymbolValue(epp, this.fileName, this.procName, this.getProcExecuted()));
			}
		}

		if (this.ddStmtAmlgnCtxs == null) {
		} else {
			for (JCLParser.DdStatementAmalgamationContext d: this.ddStmtAmlgnCtxs) {
				this.ddStatements.add(new DdStatementAmalgamation(d, this.procName, this.fileName));
			}
		}	
	}

	public Boolean isExecProc() {
		return this.execProcStmtCtx != null;
	}

	public Boolean isExecPgm() {
		return this.execPgmStmtCtx != null;
	}

	public Boolean needsProc() {
		return this.isExecProc() && (this.proc == null);
	}

	public String getProcExecuted() {
		return this.procExecuted.getValue();
	}

	public void setProc(Proc proc) {
		this.proc = proc;
	}

	public Proc getProc() {
		return this.proc;
	}

	public int getLine() {
		return this.line;
	}

	public ArrayList<Symbolic> collectSymbolics() {
		this.LOGGER.fine(this.myName + " collectSymbolics");

		ArrayList<Symbolic> symbolics = new ArrayList<>();

		if (this.isExecPgm()) {
			symbolics.addAll(this.pgmExecuted.collectSymbolics());
		} else {
			symbolics.addAll(this.procExecuted.collectSymbolics());
		}

		for (DdStatementAmalgamation d: this.ddStatements) {
			symbolics.addAll(d.collectSymbolics());
		}

		return symbolics;
	}

	public void resolveParms(ArrayList<SetSymbolValue> setSym) {
		/*
			Symbolics come from SET statements and dynamic system symbols defined
			on the command line.

			The mergedSetSym are only created and used when executing a proc, and
			would be empty anyway if just executing a program.  We do have to take
			them into account when resolving DD statements as those are overrides or
			additions to the executed proc.
		*/
		this.LOGGER.finest(myName + " " + this.stepName + " resolveParms setSym = |" + setSym + "|");

		// TODO procExecuted & pgmExecuted resolveParms(mergedSetSym)

		if (this.proc != null) {
			ArrayList<SetSymbolValue> mergedSetSym = new ArrayList<>(setSym);
			mergedSetSym.addAll(this.setSym);
			this.proc.resolveParms();
			for (DdStatementAmalgamation dda: ddStatements) {
				dda.resolveParms(mergedSetSym);
			}
		} else {
			for (DdStatementAmalgamation dda: ddStatements) {
				dda.resolveParms(setSym);
			}
		}
	}

	public void resolveProc(Job myJob) throws IOException {
		this.LOGGER.fine(this.myName + " resolveProc " + this.getProcExecuted());

		if (this.needsProc()) {
			String aProcFile = myJob.searchProcPathsFor(this.getProcExecuted());
			if (aProcFile == null) {
				this.LOGGER.warning(this + " proc not found");
			} else {
				ArrayList<Proc> procs = new ArrayList<>();
				this.lexAndParse(procs, aProcFile);
			}

		}
	}

	public void lexAndParse(ArrayList<Proc> procs, String fileName) throws IOException {
		this.LOGGER.fine(this.myName + " lexAndParse procs = |" + procs + "| fileName = |" + fileName + "|");

		CharStream cs = CharStreams.fromFileName(fileName);  //load the file
		JCLLexer jcllexer = new JCLLexer(cs);  //instantiate a lexer
		CommonTokenStream jcltokens = new CommonTokenStream(jcllexer); //scan stream for tokens
		JCLParser jclparser = new JCLParser(jcltokens);  //parse the tokens	

		ParseTree jcltree = jclparser.startRule(); // parse the content and get the tree
	
		ParseTreeWalker jclwalker = new ParseTreeWalker();
	
		JobListener jobListener = new JobListener(null, procs, fileName, LOGGER, CLI);
	
		this.LOGGER.finer(this.myName + " ----------walking tree with " + jobListener.getClass().getName());
	
		jclwalker.walk(jobListener, jcltree);

	}

	public UUID getUUID() {
		return this.uuid;
	}

	public String toString() {
		StringBuffer sb = new StringBuffer(this.myName);

		sb.append(" " + this.stepName);

		if (this.isExecProc()) {
			sb.append(" proc " + this.procExecuted.getValue());
		} else {
			sb.append(" pgm " + this.pgmExecuted.getValue());
		}

		return sb.toString();
	}
}
