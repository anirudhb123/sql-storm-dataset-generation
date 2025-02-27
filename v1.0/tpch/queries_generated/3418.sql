WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        partsupp ps
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 0
    GROUP BY 
        ps.ps_partkey
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalLinedValue,
        COUNT(CASE WHEN l.l_discount > 0 THEN 1 END) AS DiscountedLines
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey AS OrderNumber,
    r.o_orderdate AS OrderDate,
    r.o_totalprice AS TotalOrderPrice,
    r.c_mktsegment AS MarketSegment,
    COALESCE(l.TotalLinedValue, 0) AS TotalLineValue,
    COALESCE(l.DiscountedLines, 0) AS TotalDiscountedLines,
    COALESCE(s.TotalSupplyCost, 0) AS TotalSupplyCost
FROM 
    RankedOrders r
LEFT JOIN 
    LineItemSummary l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierCosts s ON s.ps_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
WHERE 
    r.OrderRank <= 10
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice DESC;
