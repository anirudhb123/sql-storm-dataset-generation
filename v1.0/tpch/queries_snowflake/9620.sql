
WITH RECURSIVE supplier_chain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ps.ps_supplycost,
        ROW_NUMBER() OVER(PARTITION BY s.s_suppkey ORDER BY ps.ps_availqty DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    WHERE ps.ps_availqty > 0
), 
top_suppliers AS (
    SELECT 
        s.s_nationkey,
        SUM(sc.ps_supplycost) AS total_supplycost
    FROM supplier_chain sc
    JOIN supplier s ON sc.s_suppkey = s.s_suppkey
    WHERE sc.rank <= 5
    GROUP BY s.s_nationkey
), 
nation_summary AS (
    SELECT 
        n.n_name,
        n.n_nationkey,
        COALESCE(ts.total_supplycost, 0) AS total_supplycost,
        COALESCE(s.count_suppliers, 0) AS count_suppliers
    FROM nation n
    LEFT JOIN (
        SELECT 
            n.n_nationkey,
            COUNT(DISTINCT s.s_suppkey) AS count_suppliers
        FROM supplier s
        GROUP BY n.n_nationkey
    ) s ON n.n_nationkey = s.n_nationkey
    LEFT JOIN top_suppliers ts ON n.n_nationkey = ts.s_nationkey
)
SELECT 
    ns.n_name,
    ns.total_supplycost,
    ns.count_suppliers
FROM nation_summary ns
ORDER BY ns.total_supplycost DESC, ns.count_suppliers DESC
LIMIT 10;
