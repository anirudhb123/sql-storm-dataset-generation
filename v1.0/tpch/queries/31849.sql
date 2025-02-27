WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
)
SELECT 
    n.n_name AS Nation, 
    rg.r_name AS Region,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice END), 0) AS TotalReturned,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    STRING_AGG(DISTINCT p.p_name, ', ') AS ProductNames,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(o.o_totalprice) DESC) AS OrderRank
FROM region rg
JOIN nation n ON rg.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE o.o_orderstatus = 'F'
GROUP BY n.n_name, rg.r_name
HAVING SUM(COALESCE(l.l_quantity, 0)) > 1000
ORDER BY TotalReturned DESC, TotalOrders ASC;
