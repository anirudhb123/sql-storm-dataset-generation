WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, s2.s_acctbal, sh.level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.s_nationkey
    WHERE s2.s_acctbal > sh.s_acctbal
)
SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_discounted_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_quantity) DESC) AS rank,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Demand'
        ELSE 'Low Demand'
    END AS demand_category
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND l.l_returnflag IS NULL
    AND n.n_name LIKE 'A%' 
GROUP BY p.p_partkey, p.p_name
HAVING SUM(l.l_quantity) IS NOT NULL 
   AND SUM(l.l_quantity) > 50
ORDER BY total_quantity DESC
LIMIT 10;