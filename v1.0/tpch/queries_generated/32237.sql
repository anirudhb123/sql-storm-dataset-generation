WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
    UNION ALL
    SELECT o2.o_orderkey, o2.o_orderdate, o2.o_totalprice, o2.o_orderstatus, 
           ROW_NUMBER() OVER (PARTITION BY o2.o_orderkey ORDER BY o2.o_orderdate) AS rn
    FROM orders o2
    INNER JOIN OrderHierarchy oh ON o2.o_custkey = oh.o_orderkey
)
SELECT p.p_name, 
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
       AVG(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY p.p_partkey) AS avg_sales_per_part,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns,
       STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN lineitem l ON l.l_partkey = p.p_partkey
JOIN OrderHierarchy o ON l.l_orderkey = o.o_orderkey
WHERE p.p_size IN (SELECT DISTINCT p2.p_size FROM part p2 WHERE p2.p_retailprice > 100) 
AND n.r_regionkey IS NOT NULL
GROUP BY p.p_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_sales DESC, total_orders DESC
FETCH FIRST 50 ROWS ONLY;
