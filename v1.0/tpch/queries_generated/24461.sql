WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           CAST(s.s_name AS varchar(100)) AS full_name,
           0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)
    
    UNION ALL
    
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, s2.s_acctbal, 
           CONCAT(sh.full_name, ' -> ', s2.s_name) AS full_name,
           sh.level + 1
    FROM SupplierHierarchy sh
    JOIN supplier s2 ON sh.s_suppkey = s2.s_suppkey
    WHERE sh.level < 3
)
SELECT n.n_name AS nation, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
       MAX(l.l_shipdate) AS latest_ship_date,
       CASE 
           WHEN AVG(s.s_acctbal) IS NULL THEN 'No balance'
           ELSE AVG(s.s_acctbal) 
       END AS avg_supplier_balance,
       LEAST(0, MAX(c.c_acctbal - SUM(l.l_extendedprice * (1 - l.l_discount)))) AS negative_revenue
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
WHERE EXISTS (
    SELECT 1 
    FROM order o 
    WHERE c.c_custkey = o.o_custkey 
      AND o.o_orderdate <= CURRENT_DATE - INTERVAL '30 days'
) 
AND COALESCE(p.p_size, 0) < 100
GROUP BY n.n_name
HAVING COUNT(l.l_orderkey) > 5
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY
UNION ALL
SELECT 'Composite Total' AS nation, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       '' AS part_names,
       MAX(l.l_shipdate) AS latest_ship_date,
       AVG(s.s_acctbal) AS avg_supplier_balance,
       NULL AS negative_revenue
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN supplier s ON s.s_suppkey = l.l_suppkey
WHERE o.o_orderstatus IN ('O', 'F')
GROUP BY o.o_orderstatus
HAVING SUM(l.l_quantity) > 1000
ORDER BY total_revenue DESC;
