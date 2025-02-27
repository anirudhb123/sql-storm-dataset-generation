WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, CONCAT(sh.s_name, ' -> ', s.s_name), 
           sh.s_acctbal + s.s_acctbal, 
           ROW_NUMBER() OVER (ORDER BY sh.s_acctbal + s.s_acctbal DESC)
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_suppkey = s.s_suppkey
    WHERE sh.rnk < 10
), 
order_totals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey
), 
region_summary AS (
    SELECT r.r_name, 
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           AVG(s.s_acctbal) AS avg_supplier_acctbal
    FROM region r
    LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
    GROUP BY r.r_name
)
SELECT ps.ps_partkey, p.p_name, 
       COALESCE((SELECT SUM(ps_availqty) FROM partsupp ps2 WHERE ps2.ps_partkey = ps.ps_partkey), 0) AS total_avail_qty,
       (SELECT SUM(total_price) FROM order_totals ot WHERE ot.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal > 1000))) AS total_ordered,
       r.r_name,
       (SELECT COUNT(*) FROM supplier_hierarchy) AS total_suppliers,
       CASE WHEN ps.ps_supplycost IS NULL THEN 'Unknown Cost' 
            ELSE 'Known Cost' END AS cost_status
FROM partsupp ps
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN region_summary r ON r.nation_count > 2
WHERE (p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)) AND (p.p_mfgr LIKE '%ABC%' OR p.p_brand IS NOT NULL)
ORDER BY total_avail_qty DESC, total_ordered DESC
LIMIT 100;
