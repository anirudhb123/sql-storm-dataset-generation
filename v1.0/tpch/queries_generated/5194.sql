WITH SupplierStats AS (
    SELECT 
        s.n_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalOrderValue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
CombinedStats AS (
    SELECT 
        r.r_name,
        COALESCE(ss.TotalSupplyCost, 0) AS TotalSupplyCost,
        COALESCE(ss.SupplierCount, 0) AS SupplierCount,
        COALESCE(co.TotalOrders, 0) AS TotalOrders,
        COALESCE(co.TotalOrderValue, 0) AS TotalOrderValue
    FROM 
        region r
    LEFT JOIN 
        SupplierStats ss ON r.r_regionkey = ss.n_nationkey
    LEFT JOIN 
        CustomerOrders co ON r.r_regionkey = co.c_nationkey
)
SELECT 
    r_name,
    TotalSupplyCost,
    SupplierCount,
    TotalOrders,
    TotalOrderValue,
    (TotalOrderValue / NULLIF(TotalOrders, 0)) AS AvgOrderValue,
    (TotalSupplyCost / NULLIF(SupplierCount, 0)) AS AvgSupplyCostPerSupplier
FROM 
    CombinedStats
ORDER BY 
    TotalOrderValue DESC, TotalSupplyCost DESC;
