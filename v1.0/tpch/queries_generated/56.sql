WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
LineItemAnalysis AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS AdjustedRevenue,
        COUNT(*) AS ItemCount,
        MAX(li.l_shipdate) AS LastShipDate
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey, li.l_partkey
)
SELECT 
    o.OrderRank,
    oh.CustomMktSegment,
    COUNT(DISTINCT l.l_partkey) AS DistinctParts,
    MAX(l.LastShipDate) AS LatestShippingDate,
    SUM(l.AdjustedRevenue) AS TotalRevenue
FROM 
    RankedOrders o
JOIN 
    LineItemAnalysis l ON o.o_orderkey = l.l_orderkey
JOIN 
    HighValueSuppliers s ON l.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
LEFT JOIN (
    SELECT 
        c.c_mktsegment AS CustomMktSegment,
        SUM(oi.o_totalprice) AS TotalOrderPrice
    FROM 
        customer c
    JOIN 
        orders oi ON c.c_custkey = oi.o_custkey
    GROUP BY 
        c.c_mktsegment
) oh ON true
WHERE 
    o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
GROUP BY 
    o.OrderRank, oh.CustomMktSegment
ORDER BY 
    o.OrderRank ASC, TotalRevenue DESC;
