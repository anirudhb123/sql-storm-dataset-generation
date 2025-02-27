WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS PriceRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2024-01-01'
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
),
NotSuppliedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(sp.TotalSupplyCost, 0) AS TotalSupplyCost
    FROM 
        part p
    LEFT JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
    WHERE 
        p.p_size > 20
),
OrderSummary AS (
    SELECT 
        r.n_name AS RegionName,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSales,
        AVG(o.o_totalprice) AS AvgOrderValue
    FROM 
        RankedOrders o
    JOIN 
        nation n ON o.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.PriceRank <= 5
    GROUP BY 
        r.n_name
)
SELECT 
    n.n_name,
    o.TotalOrders,
    o.TotalSales,
    o.AvgOrderValue,
    np.p_name,
    np.TotalSupplyCost
FROM 
    OrderSummary o
JOIN 
    nation n ON o.RegionName = n.n_name
LEFT JOIN 
    NotSuppliedParts np ON np.TotalSupplyCost IS NULL
WHERE 
    o.TotalSales > 50000
ORDER BY 
    o.TotalSales DESC, n.n_name ASC;
