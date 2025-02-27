WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s2 ON s2.s_nationkey = sh.s_nationkey
    WHERE sh.s_suppkey <> s2.s_suppkey
), 
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
      AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
), 
nation_info AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT ns.n_name, ns.r_name, SUM(os.total_revenue) AS total_revenue, 
       ROW_NUMBER() OVER (PARTITION BY ns.r_name ORDER BY SUM(os.total_revenue) DESC) AS revenue_rank,
       CASE 
           WHEN COUNT(DISTINCT sh.s_suppkey) > 3 THEN 'High Supplier Diversity'
           WHEN COUNT(DISTINCT sh.s_suppkey) = 0 THEN 'No Suppliers'
           ELSE 'Moderate Supplier Diversity'
       END AS supplier_diversity
FROM order_summary os
JOIN nation_info ns ON (os.o_orderkey % 10 = ns.n_nationkey OR ns.n_nationkey IS NULL)
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = ns.n_nationkey
WHERE ns.n_name IS NOT NULL OR ns.r_name LIKE '%Region%'
GROUP BY ns.n_name, ns.r_name
HAVING SUM(os.total_revenue) > (SELECT AVG(total_revenue) FROM order_summary)
   OR EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_availqty IS NULL)
ORDER BY total_revenue DESC
FETCH FIRST 50 ROWS ONLY;
