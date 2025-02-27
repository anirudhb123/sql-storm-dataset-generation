WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01'
        AND l.l_shipdate <= DATE '2023-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.RegionName,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    COALESCE(SUM(t.TotalRevenue), 0) AS TotalRevenue,
    COALESCE(SUM(sd.TotalSupplyCost), 0) AS TotalSupplyCost,
    AVG(o.o_totalprice) AS AverageOrderValue
FROM 
    RankedOrders o
LEFT JOIN 
    TotalLineItems t ON o.o_orderkey = t.l_orderkey
LEFT JOIN 
    supplier s ON s.s_suppkey = t.l_orderkey
LEFT JOIN 
    (SELECT 
         n.n_name AS RegionName, 
         rg.r_name, 
         r.r_regionkey 
     FROM 
         nation n 
     JOIN 
         region r ON n.n_regionkey = r.r_regionkey) r ON r.r_regionkey = s.s_nationkey
LEFT JOIN 
    SupplierDetails sd ON sd.s_nationkey = r.r_regionkey
WHERE 
    o.o_orderstatus IN ('O', 'F')
GROUP BY 
    r.RegionName
ORDER BY 
    TotalRevenue DESC
LIMIT 10;
