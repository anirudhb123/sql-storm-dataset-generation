
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
), PopularParts AS (
    SELECT p.p_partkey, p.p_name, COUNT(l.l_orderkey) AS OrderCount
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    ORDER BY OrderCount DESC
    LIMIT 10
)
SELECT r.r_name AS Region, 
       SUM(COALESCE(hc.TotalSpent, 0)) AS TotalSpentByHighValueCustomers,
       SUM(COALESCE(rs.TotalCost, 0)) AS TotalCostOfSuppliers,
       COUNT(DISTINCT pp.p_partkey) AS PopularPartCount
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN HighValueCustomers hc ON s.s_nationkey = hc.c_custkey
LEFT JOIN PopularParts pp ON pp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
WHERE r.r_name IN ('ASIA', 'EUROPE') 
GROUP BY r.r_name
ORDER BY r.r_name;
