import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.*;

public class CompilerOptionsWrapper {

	private String myName = this.getClass().getName();
	private CobolPreprocessorParser.CompilerOptionsContext coCtx = null;
	private int line = -1;

	CompilerOptionsWrapper(CobolPreprocessorParser.CompilerOptionsContext ctx) {
		this.coCtx = ctx;
	}

	public int getLine() {
		if (this.line < 0) {
			if (this.coCtx.PROCESS() == null) {
				this.line = this.coCtx.CBL().getSymbol().getLine();
			} else {
				this.line = this.coCtx.PROCESS().getSymbol().getLine();
			}
		}

		return this.line;
	}

}
