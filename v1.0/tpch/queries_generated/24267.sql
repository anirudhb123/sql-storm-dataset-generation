WITH RECURSIVE CTE_Supplier AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment,
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rnk
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment,
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC)
    FROM supplier s
    JOIN CTE_Supplier c ON s.s_acctbal < c.s_acctbal
)
SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       CASE
           WHEN AVG(COALESCE(s.s_acctbal, 0)) > 1000 THEN 'High Value Supplier'
           ELSE 'Low Value Supplier'
       END AS supplier_value_category
FROM nation n
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN partsupp ps ON ps.ps_partkey = l.l_partkey
LEFT JOIN CTE_Supplier cs ON cs.s_suppkey = ps.ps_suppkey
WHERE (o.o_orderstatus = 'O' OR o.o_orderstatus = 'F')
      AND (n.r_regionkey IS NOT NULL)
      AND l.l_discount BETWEEN 0.01 AND 0.5
      AND (l.l_shipmode NOT LIKE '%FREIGHT%' OR l.l_shipdate IS NULL)
      AND EXISTS (
          SELECT 1
          FROM part p 
          WHERE p.p_partkey = l.l_partkey AND p.p_retailprice IS NOT NULL
      )
GROUP BY n.n_name
HAVING SUM(l.l_quantity) IS NOT NULL AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
