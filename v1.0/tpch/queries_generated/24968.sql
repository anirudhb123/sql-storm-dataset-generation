WITH RECURSIVE NationHierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 0 AS Level
    FROM nation n
    WHERE n.n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, Level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT o.o_custkey) AS UniqueCustomers,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierEngagement AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS SuppliedParts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
Extremes AS (
    SELECT 
        p.p_partkey,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS ReturnCount,
        MAX(l.l_shipdate) AS LastShipDate,
        MIN(l.l_tax) AS MinTax
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
),
FinalResults AS (
    SELECT 
        nh.n_name,
        SUM(os.TotalRevenue) AS TotalRevenueByRegion,
        SUM(se.TotalSupplyCost) AS TotalCostBySupplier,
        COUNT(DISTINCT es.p_partkey) AS UniquePartsSupplied
    FROM NationHierarchy nh
    LEFT JOIN OrderStats os ON nh.n_nationkey = os.o_orderkey
    LEFT JOIN SupplierEngagement se ON nh.n_nationkey = se.s_suppkey
    CROSS JOIN Extremes es
    GROUP BY nh.n_name
)
SELECT 
    fr.n_name,
    fr.TotalRevenueByRegion,
    fr.TotalCostBySupplier,
    fr.UniquePartsSupplied,
    CASE 
        WHEN fr.TotalRevenueByRegion IS NULL THEN 'No Revenue'
        WHEN fr.TotalRevenueByRegion > 50000 THEN 'High Revenue'
        ELSE 'Regular Revenue'
    END AS RevenueCategory
FROM FinalResults fr
WHERE fr.TotalRevenueByRegion IS NOT NULL
ORDER BY fr.TotalRevenueByRegion DESC
LIMIT 10;
