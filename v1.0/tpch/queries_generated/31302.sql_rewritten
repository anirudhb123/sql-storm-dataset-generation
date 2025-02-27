WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) 
        FROM supplier 
        WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'Germany')
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
SELECT 
    n.n_name AS Nation,
    p.p_name AS Part_Name,
    COUNT(DISTINCT o.o_orderkey) AS Order_Count,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS Total_Value,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS Rank
FROM lineitem li
JOIN orders o ON li.l_orderkey = o.o_orderkey
JOIN partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE o.o_orderdate >= DATE '1996-01-01' 
AND o.o_orderdate < DATE '1997-01-01'
AND (p.p_size IS NULL OR p.p_size BETWEEN 1 AND 10)
GROUP BY n.n_name, p.p_name
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY Nation, Total_Value DESC;