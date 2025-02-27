WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
    HAVING SUM(o.o_totalprice) > 100000
),
RegionSummary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS NationCount,
        SUM(CASE WHEN s.s_nationkey IN (SELECT n.n_nationkey FROM HighValueCustomers) THEN 1 ELSE 0 END) AS HighValueSupplierCount
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    rs.r_regionkey,
    rs.r_name,
    rs.NationCount,
    rs.HighValueSupplierCount,
    hs.TotalSpent
FROM RegionSummary rs
JOIN HighValueCustomers hs ON rs.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = hs.c_nationkey)
ORDER BY rs.r_regionkey, hs.TotalSpent DESC;
