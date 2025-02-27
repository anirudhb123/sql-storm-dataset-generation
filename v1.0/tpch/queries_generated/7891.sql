WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationAggregate AS (
    SELECT n.n_nationkey, n.n_name, SUM(sd.TotalCost) AS AggregateCost
    FROM SupplierDetails sd
    JOIN nation n ON sd.s_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
RegionSummary AS (
    SELECT r.r_regionkey, r.r_name, SUM(na.AggregateCost) AS TotalNationCost
    FROM NationAggregate na
    JOIN nation n ON na.n_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS RegionName,
    COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
    AVG(na.AggregateCost) AS AvgSupplierCost,
    MAX(na.AggregateCost) AS MaxSupplierCost,
    MIN(na.AggregateCost) AS MinSupplierCost
FROM RegionSummary r
JOIN NationAggregate na ON r.r_regionkey = na.n_nationkey
JOIN supplier s ON na.n_nationkey = s.s_nationkey
GROUP BY r.r_name
ORDER BY TotalNationCost DESC
LIMIT 10;
