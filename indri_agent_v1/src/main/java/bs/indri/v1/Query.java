package bs.indri.v1;

import java.util.Map;

public class Query {
	public Query() {
		System.out.println("BEGIN: " + query_begin(null, null));
	}

	static {
		System.loadLibrary("bs_indri_v1_Query");
	}
	private native int query_begin(String indexPaths[], String query);
	// private native Map<String, Object> query_next_results(int queryId, int resultCount,
	// 													  String fields[]);
	// private native void query_close(int queryId);
}
