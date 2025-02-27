WITH RECURSIVE top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) as rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, r.rnk + 1
    FROM supplier s
    JOIN top_suppliers r ON s.s_a_suppkey = r.s_suppkey 
    WHERE r.rnk < 10
),
orders_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O') 
    GROUP BY o.o_orderkey
),
supplier_parts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
filtered_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice 
    FROM part p
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2
    )
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) as supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    COALESCE(SUM(os.total_sales), 0) AS total_sales,
    COUNT(DISTINCT sp.ps_suppkey) AS supplier_count,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM nation_summary ns
LEFT JOIN orders_summary os ON ns.n_nationkey = os.o_orderkey
LEFT JOIN supplier_parts sp ON ns.n_nationkey = sp.ps_suppkey
LEFT JOIN filtered_parts p ON sp.ps_partkey = p.p_partkey
WHERE ns.supplier_count >= 1
GROUP BY ns.n_name
HAVING COUNT(DISTINCT sp.ps_suppkey) > 3
ORDER BY total_sales DESC;
