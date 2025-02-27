WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderstatus, 
        o.o_orderdate,
        o.o_totalprice, 
        1 AS OrderLevel
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'  
    
    UNION ALL
    
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderstatus, 
        o.o_orderdate,
        o.o_totalprice, 
        oh.OrderLevel + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON oh.o_custkey = o.o_custkey 
    WHERE 
        o.o_orderstatus IN ('F', 'C')  
        AND o.o_orderdate > cast('1998-10-01' as date) - INTERVAL '1 year'  
), AggregateLineItems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        COUNT(*) AS ItemCount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied,
        AVG(s.s_acctbal) AS AvgSupplierBalance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey
), ExtendedReport AS (
    SELECT 
        oh.o_orderkey,
        oh.o_orderdate,
        al.TotalSales,
        si.UniquePartsSupplied,
        si.AvgSupplierBalance
    FROM 
        OrderHierarchy oh
    JOIN 
        AggregateLineItems al ON oh.o_orderkey = al.l_orderkey
    JOIN 
        supplier s ON al.TotalSales > s.s_acctbal
    JOIN 
        SupplierInfo si ON si.s_suppkey = s.s_suppkey
)
SELECT 
    e.o_orderkey,
    e.o_orderdate,
    e.TotalSales,
    COALESCE(e.UniquePartsSupplied, 0) AS UniqueParts,
    ROUND(e.AvgSupplierBalance, 2) AS AverageBalance
FROM 
    ExtendedReport e
WHERE 
    e.TotalSales > (SELECT AVG(TotalSales) FROM AggregateLineItems)
ORDER BY 
    e.TotalSales DESC
LIMIT 50;