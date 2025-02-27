WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE sh.level < 5 AND p.p_size < 20
)
SELECT r.r_name AS region_name,
       n.n_name AS nation_name,
       COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
       AVG(s.s_acctbal) AS avg_acctbal,
       COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM supplier s
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
WHERE o.o_orderstatus = 'F'
  AND p.p_brand IS NOT NULL
  AND (l.l_returnflag = 'R' OR l.l_returnflag IS NULL)
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
   OR AVG(s.s_acctbal) > 2000
ORDER BY total_sales DESC
FETCH FIRST 10 ROWS ONLY;
