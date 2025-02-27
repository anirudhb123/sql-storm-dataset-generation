WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 
           CAST(s_name AS VARCHAR(255)) AS hierarchy_path
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           CONCAT(sh.hierarchy_path, ' -> ', s.s_name)
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           o.o_orderdate, o.o_orderstatus, COUNT(l.l_linenumber) AS total_lines
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'P')
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
nation_region AS (
    SELECT n.n_nationkey, n.n_name, r.r_name,
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY n.n_nationkey) AS nation_rank
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice, 
    ns.n_name AS supplier_nation, 
    COALESCE(s.s_acctbal, 0) AS supplier_acctbal, 
    os.total_revenue,
    nr.nation_rank,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Sales'
        ELSE 'Sold'
    END AS sales_status
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier_hierarchy s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN order_summary os ON os.total_lines > 5
LEFT JOIN nation_region nr ON s.s_nationkey = nr.n_nationkey
WHERE p.p_retailprice > 50.00
AND (s.s_acctbal IS NULL OR s.s_acctbal > 5000)
ORDER BY p.p_partkey, ns.n_name;
