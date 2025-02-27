WITH SupplierPartCosts AS (
    SELECT 
        s.s_name,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        (ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
AverageCost AS (
    SELECT 
        s_name,
        AVG(TotalCost) AS AvgSupplierCost
    FROM SupplierPartCosts
    GROUP BY s_name
),
HighCostSuppliers AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost) AS TotalSupplierCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
    HAVING SUM(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    r.r_name AS Region,
    COUNT(DISTINCT ns.n_name) AS NumberOfNations,
    COUNT(DISTINCT c.c_custkey) AS TotalCustomers,
    SUM(l.l_extendedprice) AS TotalLineItemRevenue,
    MAX(ac.AvgSupplierCost) AS HighestAverageCost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN AverageCost ac ON ac.s_name IN (SELECT s.s_name FROM supplier s JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey)
LEFT JOIN HighCostSuppliers hs ON hs.s_name = ac.s_name
GROUP BY r.r_name
ORDER BY TotalLineItemRevenue DESC; 
