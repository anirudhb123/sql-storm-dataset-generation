
WITH SupplierCost AS (
    SELECT s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
NationCost AS (
    SELECT n.n_regionkey, SUM(sc.total_cost) AS region_cost
    FROM nation n
    JOIN SupplierCost sc ON n.n_nationkey = sc.s_nationkey
    GROUP BY n.n_regionkey
),
TopRegions AS (
    SELECT r.r_name, nc.region_cost
    FROM region r
    JOIN NationCost nc ON r.r_regionkey = nc.n_regionkey
    ORDER BY nc.region_cost DESC
    LIMIT 5
)
SELECT 
    tr.r_name AS Region, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    AVG(c.c_acctbal) AS AverageAccountBalance,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN TopRegions tr ON tr.r_name = (SELECT distinct r.r_name FROM region r WHERE r.r_regionkey = c.c_nationkey)
GROUP BY tr.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000000
ORDER BY TotalRevenue DESC;
