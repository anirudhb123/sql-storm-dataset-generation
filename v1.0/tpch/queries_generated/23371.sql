WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CAST(NULL AS DECIMAL(12,2)) AS ParentBalance 
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           sh.s_acctbal AS ParentBalance
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'BrandX') LIMIT 1)
)

SELECT n.n_name, r.r_name,
       COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
       AVG(CASE WHEN l.l_returnflag = 'R' THEN NULL ELSE l.l_quantity END) AS AvgQuantity,
       MAX(STRING_AGG(DISTINCT s.s_name, ', ')) AS SupplierNames
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT OUTER JOIN SupplierHierarchy sh ON l.l_suppkey = sh.s_suppkey
GROUP BY n.n_name, r.r_name
HAVING SUM(CASE WHEN sh.ParentBalance IS NULL THEN 0 ELSE sh.ParentBalance END) > 10000
ORDER BY TotalOrders DESC
FETCH FIRST 10 ROWS ONLY;
