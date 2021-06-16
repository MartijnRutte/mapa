import java.util.*;
import java.io.*;
import java.nio.file.*;
import java.util.logging.Logger;
import java.util.logging.Level;
import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.*;

public class BasisStatement implements CompilerDirectingStatement {

	private String myName = this.getClass().getName();
	private Logger LOGGER = null;
	private TheCLI CLI = null;
	private CobolPreprocessorParser.CompilerDirectiveBasisContext ctx = null;
	private CompilerDirectingStatementType type = CompilerDirectingStatementType.STMT_BASIS;
	private ArrayList<InsertStatement> insertStatements = new ArrayList<>();
	private ArrayList<DeleteStatement> deleteStatements = new ArrayList<>();
	private int startLine = -1;
	private int endLine = -1;

	BasisStatement(
			CobolPreprocessorParser.CompilerDirectiveBasisContext ctx
			, Logger LOGGER
			, TheCLI CLI
			) {
		this.LOGGER = LOGGER;
		this.CLI = CLI;
		this.ctx = ctx;
		this.startLine = this.ctx.start.getLine();
		this.endLine = this.ctx.stop.getLine();
	}

	public int getLine() {
		return this.startLine;
	}

	public int getEndLine() {
		return this.endLine;
	}

	public CompilerDirectingStatementType getType() {
		return this.type;
	}

	public String getBasisName() {
		String prelim = this.ctx.basisName().getText();
		String fileName = null;

		if (prelim.startsWith("'")) {
			// 'fileName' should return fileName
			fileName = prelim.substring(1, prelim.length() - 1);
		} else if (prelim.startsWith("\"")) {
			// "fileName" should return fileName
			fileName = prelim.substring(1, prelim.length() - 1);
		} else {
			fileName = new String(prelim);
		}

		return fileName;
	}

	public void addInsertStatement(InsertStatement insertStatement) {
		this.insertStatements.add(insertStatement);
	}

	public void addDeleteStatement(DeleteStatement deleteStatement) {
		this.deleteStatements.add(deleteStatement);
	}

	public String mergeWithSource(
				String initFileNm
				, String currTempFile
				, File baseDir
				, String dir
				) throws IOException {
		this.LOGGER.fine(myName + " mergeWithSource()");
		this.distributeSource(currTempFile);
		LineNumberReader basis = new LineNumberReader(new FileReader( new File(dir + File.separatorChar + this.getBasisName())));
		File tmp = File.createTempFile("CallTree-" + initFileNm + "-frombasis-", "-cbl", baseDir);
		this.CLI.setPosixAttributes(tmp);
		if (this.CLI.saveTemp) {
		} else {
			tmp.deleteOnExit();
		}

		PrintWriter out = new PrintWriter(tmp);
		String basisLine = basis.readLine();
		int basisLineNb = basis.getLineNumber();

		while (basisLine != null) {
			InsertStatement insertStatement = this.applicableInsertStatement(basisLineNb);
			DeleteStatement deleteStatement = this.applicableDeleteStatement(basisLineNb);
			if (insertStatement != null) {
				out.println(basisLine);
				for (String aNewLine: insertStatement.getSrc()) {
					out.println(aNewLine);
				}
			} else if (deleteStatement != null) {
				if (deleteStatement.isLastTargetLine(basisLineNb)) {
					for (String aNewLine: deleteStatement.getSrc()) {
						out.println(aNewLine);
					}
				}
			} else {
				out.println(basisLine);
			}
			basisLine = basis.readLine();
			basisLineNb = basis.getLineNumber();
		}

		out.close();
		return tmp.getAbsolutePath();
	}

	private void distributeSource(String currTempFile) throws IOException {
		this.LOGGER.fine(myName + " distributeSource()");
		LineNumberReader src = new LineNumberReader(new FileReader( new File(currTempFile)));
		String srcLine = src.readLine(); //this should be the BASIS statement
		int srcLineNb = src.getLineNumber();
		InsertStatement assignedInsert = null;
		DeleteStatement assignedDelete = null;
		Boolean isCode = false; //because this should be the BASIS statement

		while (srcLine != null) {
			for (InsertStatement insertStatement: this.insertStatements) {
				if (srcLineNb == insertStatement.getLine()) {
					/*
					Lines that are neither INSERT nor DELETE lines following 
					this one are to be assigned to this 
					insertStatement; up until the next insert or delete
					statement.
					*/
					assignedInsert = insertStatement;
					assignedDelete = null;
					isCode = false;
					break;
				}
			}
			for (DeleteStatement deleteStatement: this.deleteStatements) {
				if (srcLineNb == deleteStatement.getLine()) {
					/*
					Lines that are neither INSERT nor DELETE lines following 
					this one are to be assigned to this 
					deleteStatement; up until the next insert or delete
					statement.
					*/
					assignedDelete = deleteStatement;
					assignedInsert = null;
					isCode = false;
					break;
				}
			}
			if (isCode && assignedInsert != null) {
				assignedInsert.addSrc(srcLine);
			}
			if (isCode && assignedDelete != null) {
				assignedDelete.addSrc(srcLine);
			}
			srcLine = src.readLine();
			srcLineNb = src.getLineNumber();
			isCode = true;
		}

		src.close();
		this.LOGGER.fine(myName + " distributeSource() exit");
	}

	private InsertStatement applicableInsertStatement(int lineNb) {
		for (InsertStatement insertStatement: this.insertStatements) {
			if (lineNb == insertStatement.getTargetLine()) {
				return insertStatement;
			}
		}

		return null;
	}

	private DeleteStatement applicableDeleteStatement(int lineNb) {
		for (DeleteStatement deleteStatement: this.deleteStatements) {
			if (deleteStatement.appliesTo(lineNb)) {
				return deleteStatement;
			}
		}

		return null;
	}


}
