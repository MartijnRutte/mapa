
import java.util.*;
import java.util.logging.*;
import java.io.*;
import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.*;

/**
This class represents a JCL Job Step.

<p>-->NOTE This class is used as a base to create another class via a sed script 
executed in the Makefile.  The resulting file has the name of this file with 
"PP" prepended.

<p>An instance of JclStep is meaningless without its containing Job or Proc, 
which provide values for symbolics that may be present.

<p>A JclStep may execute a procedure, which may have its symbolics resolved by
values set by this JclStep.  The same procedure may be executed by several
different JclSteps in the same Job, all with different parameters.  So each
JclStep locates, parses, and provides any proc it executes its own collection
of SetSymbolValues for resolution.

<p>An unfortunate side effect of this class and its brethren being created
by an ANTLR listener class is that not all instance variables are known at
instantiation time, they must be added as they are encountered by the listener.


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
	private int jobOrdNb = 0;
	private int ordNb = 0;
	private KeywordOrSymbolicWrapper procExecuted = null;
	private KeywordOrSymbolicWrapper pgmExecuted = null;
	private Proc proc = null;
	private Boolean inProc = null;
	private JCLParser.JclStepContext jclStepCtx = null;
	private JCLParser.ExecStatementContext execStmtCtx = null;
	private JCLParser.ExecPgmStatementContext execPgmStmtCtx = null;
	private JCLParser.ExecProcStatementContext execProcStmtCtx = null;
	private List<JCLParser.DdStatementAmalgamationContext> ddStmtAmlgnCtxs = null;
	/**
	The collection setSym holds instances of SetSymbolValue representing
	parameters set on execution of a cataloged or instream procedure.
	*/
	private ArrayList<SetSymbolValue> setSym = new ArrayList<>();
	/**
	The collection incomingSetSym holds instances of SetSymbolValue
	representing parameters set by SET statements or other means prior
	to execution of this step.
	*/
	private ArrayList<SetSymbolValue> incomingSetSym = new ArrayList<>();
	private ArrayList<DdStatementAmalgamation> ddStatements = new ArrayList<>();
	private ArrayList<KeywordOrSymbolicWrapper> jcllib = new ArrayList<>();
	private File baseDir = null;
	private File tmpProcDir = null;
	private Job parentJob = null;
	private Proc parentProc = null;

	public JclStep(
			JCLParser.JclStepContext jclStepCtx
			, String fileName
			, String procName
			, Logger LOGGER
			, TheCLI CLI
			) {
		this.jclStepCtx = jclStepCtx;
		this.fileName = fileName;
		this.procName = procName;
		this.LOGGER = LOGGER;
		this.CLI = CLI;
		this.inProc = !(procName == null);
		this.initialize();
		this.LOGGER.fine(this.myName + " " + this.stepName + " instantiated from " + this.fileName);
		this.LOGGER.finest(this.myName + " procExecuted = |" + this.procExecuted + "|");
	}

	public JclStep(
			JCLParser.JclStepContext jclStepCtx
			, String fileName
			, Proc parentProc
			, Logger LOGGER
			, TheCLI CLI
			) {
		this.jclStepCtx = jclStepCtx;
		this.fileName = fileName;
		this.parentProc = parentProc;
		this.procName = parentProc.getProcName();
		this.LOGGER = LOGGER;
		this.CLI = CLI;
		this.inProc = true;
		this.initialize();
		this.LOGGER.fine(this.myName + " " + this.stepName + " instantiated from " + this.fileName);
		this.LOGGER.finest(this.myName + " procExecuted = |" + this.procExecuted + "|");
	}

	public JclStep(
			JCLParser.JclStepContext jclStepCtx
			, String fileName
			, Job parentJob
			, Logger LOGGER
			, TheCLI CLI
			) {
		this.jclStepCtx = jclStepCtx;
		this.fileName = fileName;
		this.parentJob = parentJob;
		this.LOGGER = LOGGER;
		this.CLI = CLI;
		this.inProc = false;
		this.initialize();
		this.LOGGER.fine(this.myName + " " + this.stepName + " instantiated from " + this.fileName);
		this.LOGGER.finest(this.myName + " procExecuted = |" + this.procExecuted + "|");
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
				this.stepName = "_NONAME_";
			} else {
				this.stepName = this.execPgmStmtCtx.stepName().NAME_FIELD().getSymbol().getText();
			}
			this.pgmExecuted = new KeywordOrSymbolicWrapper(this.execPgmStmtCtx.keywordOrSymbolic(), this.procName, this.LOGGER, this.CLI);
		} else {
			this.line = this.execProcStmtCtx.EXEC().getSymbol().getLine();
			if (this.execProcStmtCtx.stepName() == null) {
				this.stepName = "_NONAME_";
			} else {
				this.stepName = this.execProcStmtCtx.stepName().NAME_FIELD().getSymbol().getText();
			}
			this.procExecuted = new KeywordOrSymbolicWrapper(this.execProcStmtCtx.keywordOrSymbolic(), this.procName, this.LOGGER, this.CLI);
			for (JCLParser.ExecProcParmContext epp: this.execProcStmtCtx.execProcParm()) {
				this.setSym.add(new SetSymbolValue(epp, this.fileName, this.procName, this.getProcExecuted(), this.LOGGER, this.CLI));
			}
		}

		if (this.ddStmtAmlgnCtxs == null) {
		} else {
			for (JCLParser.DdStatementAmalgamationContext d: this.ddStmtAmlgnCtxs) {
				this.ddStatements.add(new DdStatementAmalgamation(d, this.procName, this.fileName, this.LOGGER, this.CLI));
			}
		}	
	}

	public void setTmpDirs(File baseDir, File tmpProcDir) throws IOException {
		this.LOGGER.finer(this.myName + " " + this.stepName + " setTmpDirs(" + baseDir + "," + tmpProcDir + ")");
		if (this.baseDir == null) {
			this.baseDir = baseDir;
			this.LOGGER.finest(this.myName + " " + this.stepName + " setTmpDirs baseDir set to |" + this.baseDir + "|");
		}

		if (this.tmpProcDir == null) {
			this.tmpProcDir = tmpProcDir;
			this.LOGGER.finest(this.myName + " " + this.stepName + " setTmpDirs tmpProcDir set to |" + this.tmpProcDir + "|");
		}

		this.LOGGER.fine(this.myName +  " " + this.stepName + " setTmpDirs procExecuted = |" + this.procExecuted + "|");
		
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

	public void setOrdNb(int ordNb) {
		this.ordNb = ordNb;
	}

	public void setJobOrdNb(int jobOrdNb) {
		this.jobOrdNb = jobOrdNb;
	}

	public StringBuffer getResolvedSuffix() {
		StringBuffer sb = new StringBuffer();

		if (this.parentProc == null) {
			sb.append(this.parentJob.getResolvedSuffix());
		} else {
			sb.append(this.parentProc.getResolvedSuffix());
		}

		sb.append("-");
		sb.append(String.format("%06d", this.ordNb));
		return sb;
	}

	public StringBuffer getProcFileName() {
		this.LOGGER.finest(this.myName +  " " + this.stepName + " getProcFileName procExecuted = |" + this.procExecuted + "|");
		StringBuffer sb = new StringBuffer(this.tmpProcDir.toString());
		sb.append(File.separator);
		sb.append("PPProc");
		sb.append("-");
		sb.append(this.getProcExecuted());
		sb.append("-resolved-");
		sb.append(this.getResolvedSuffix());

		return sb;
	}

	public Proc getProc() {
		return this.proc;
	}

	public Proc getParentProc() {
		return this.parentProc;
	}

	public Job getParentJob() {
		return this.parentJob;
	}

	public int getLine() {
		return this.line;
	}

	private int getFileNb() {
		if (this.parentJob == null) {
			return this.parentProc.getFileNb();
		} else {
			return this.parentJob.getFileNb();
		}
	}

	public void setJcllib(ArrayList<KeywordOrSymbolicWrapper> jcllib) {
		this.jcllib = jcllib;
	}

	public ArrayList<String> getJcllibStrings() {
		ArrayList<String> libs = new ArrayList<>();

		for (KeywordOrSymbolicWrapper k: jcllib) {
			libs.add(k.getValue());
		}

		return libs;
	}

	public ArrayList<Symbolic> collectSymbolics() {
		this.LOGGER.finer(this.myName + " collectSymbolics");

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
		this.LOGGER.finer(myName + " " + this.stepName + " resolveParms setSym = |" + setSym + "|");

		this.incomingSetSym.addAll(setSym);
		// TODO procExecuted & pgmExecuted resolveParms(mergedSetSym)

		if (this.proc != null) {
			ArrayList<SetSymbolValue> mergedSetSym = new ArrayList<>(setSym);
			mergedSetSym.addAll(this.setSym);
			this.proc.resolveParms(mergedSetSym);
			for (DdStatementAmalgamation dda: ddStatements) {
				dda.resolveParms(mergedSetSym);
			}
		} else {
			for (DdStatementAmalgamation dda: ddStatements) {
				dda.resolveParms(setSym);
			}
		}
	}

	public void resolveProc() throws IOException {
		this.LOGGER.finer(this.myName + " " + this.stepName + " resolveProc ");

		if (this.needsProc()) {
			String aProcFile = this.searchProcPathsFor(this.getProcExecuted());
			if (aProcFile == null) {
				this.LOGGER.warning(this + " proc not found");
			} else {
				ArrayList<Proc> procs = new ArrayList<>();
				this.lexAndParse(procs, aProcFile);
				procs.get(0).setJcllib(this.jcllib);
				procs.get(0).setTmpDirs(this.baseDir, this.tmpProcDir);
				procs.get(0).setOrdNb(this.ordNb);
				procs.get(0).setJobOrdNb(this.jobOrdNb);
				procs.get(0).setParentJclStep(this);
				ArrayList<SetSymbolValue> mergedSetSym = new ArrayList<>(this.incomingSetSym);
				mergedSetSym.addAll(this.setSym);
				this.proc = procs.get(0).iterativelyResolveIncludes(mergedSetSym, new File(aProcFile));
				this.proc.resolveParms(mergedSetSym);
				File finalProcFile = this.proc.rewriteWithParmsResolved();
				this.proc.resolveProcs();
			}

		}
	}

	public void lexAndParse(ArrayList<Proc> procs, String fileName) throws IOException {
		this.LOGGER.finer(this.myName + " lexAndParse procs = |" + procs + "| fileName = |" + fileName + "|");

		CharStream cs = CharStreams.fromFileName(fileName);  //load the file
		JCLLexer jcllexer = new JCLLexer(cs);  //instantiate a lexer
		CommonTokenStream jcltokens = new CommonTokenStream(jcllexer); //scan stream for tokens
		JCLParser jclparser = new JCLParser(jcltokens);  //parse the tokens	

		ParseTree jcltree = jclparser.startRule(); // parse the content and get the tree
	
		ParseTreeWalker jclwalker = new ParseTreeWalker();
	
		JobListener jobListener = new JobListener(null, procs, fileName, this.getFileNb(), LOGGER, CLI);
	
		this.LOGGER.finer(this.myName + " ----------walking tree with " + jobListener.getClass().getName());
	
		jclwalker.walk(jobListener, jcltree);

	}

	public UUID getUUID() {
		return this.uuid;
	}

	public String searchProcPathsFor(String fileName) throws IOException {
		File aFile = new File(this.tmpProcDir.getPath() + File.separator + fileName);

		this.LOGGER.finer(this.myName + " " + this.stepName + " searchProcPaths searching " + tmpProcDir);
		if (aFile.exists()) {
			this.LOGGER.finer(this.myName + " searchProcPathsFor() found " + aFile.getPath());
			return aFile.getPath();
		} else {
			this.LOGGER.finer(this.myName + " searchProcPathsFor() did not find " + aFile.getPath());
		}

		ArrayList<String> jcllib = this.getJcllibStrings();
		for (String lib: jcllib) {
			if (this.CLI.mappedProcPaths.containsKey(lib)) {
				aFile = new File(this.CLI.mappedProcPaths.get(lib) + File.separator + fileName);
				if (aFile.exists()) {
					this.LOGGER.finer(this.myName + " searchProcPathsFor() found " + aFile.getPath());
					return aFile.getPath();
				} else {
					this.LOGGER.finer(this.myName + " searchProcPathsFor() did not find " + aFile.getPath());
				}
			}
		}

		for (String path: this.CLI.staticProcPaths) {
			aFile = new File(path + File.separator + fileName);
			this.LOGGER.finer(this.myName + " " + this.stepName + " searchProcPaths searching " + path);
			if (aFile.exists()) {
				this.LOGGER.finer(this.myName + " searchProcPathsFor() found " + aFile.getPath());
				return aFile.getCanonicalPath();
			} else {
				this.LOGGER.finer(this.myName + " searchProcPathsFor() did not find " + aFile.getPath());
			}
		}

		this.LOGGER.warning(this.myName + " searchProcPathsFor() did not find " + fileName);
		this.LOGGER.finer(
			this.myName 
			+ " searchProcPathsFor() searched for " 
			+ fileName
			+ " in "
			+ this.tmpProcDir
			+ " and "
			+ this.CLI.mappedProcPaths
			+ " and even "
			+ this.CLI.staticProcPaths
			+ " without success"
			);
		return null;
	}

	public void lexAndParseProc() throws IOException {
		this.LOGGER.fine(this.myName + " " + this.stepName + " lexAndParseProc");
		if (this.isExecProc()) {
			this.LOGGER.fine(
						this.myName 
						+ " " 
						+ this.stepName 
						+ " lexAndParseProc procName = |" 
						+ this.procName 
						+ "|"
						);
			File aFile = new File(this.getProcFileName().toString());
			if (aFile.exists()) {
				this.LOGGER.fine(
							this.myName 
							+ " " 
							+ this.stepName 
							+ " lexAndParseProc aFile.getName() = |" 
							+ aFile.getName() 
							+ "| exists"
							);
				ArrayList<Proc> procs = new ArrayList<>();
				String fileName = this.getProcFileName().toString();
				this.lexAndParse(procs, fileName);
				this.proc = procs.get(0);
				procs.get(0).setJcllib(this.jcllib);
				procs.get(0).setTmpDirs(this.baseDir, this.tmpProcDir);
				procs.get(0).setOrdNb(this.ordNb);
				procs.get(0).setJobOrdNb(this.jobOrdNb);
				procs.get(0).setParentJclStep(this);
				this.proc.lexAndParseProcs();
			} else {
				this.LOGGER.fine(
							this.myName 
							+ " " 
							+ this.stepName 
							+ " lexAndParseProc aFile.getName() = |" 
							+ aFile.getName() 
							+ "| does not exist"
							);
			}
		}
	}

	public void toCSV(StringBuffer csvOut) {
		this.LOGGER.fine(this.myName + " " + this.stepName + " toCSV");
		csvOut.append(",");
		csvOut.append(this.stepName);
		csvOut.append(",");
		csvOut.append(this.ordNb);
		csvOut.append(",");
		if (this.isExecPgm()) {
			csvOut.append("PGM");
			csvOut.append(",");
			csvOut.append(this.pgmExecuted.getValue());
		} else {
			csvOut.append("PROC");
			csvOut.append(",");
			csvOut.append(this.procExecuted.getValue());
			if (this.proc != null) {
				csvOut.append(System.getProperty("line.separator"));
				csvOut.append(",");
				this.proc.toCSV(csvOut);
			}
			//csvOut.append(System.getProperty("line.separator"));
		}
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
