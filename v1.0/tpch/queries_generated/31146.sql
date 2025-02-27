WITH RECURSIVE SupplierCTE AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        1 AS SupplierLevel,
        NULL AS ParentSupplier
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000.00
    
    UNION ALL
    
    SELECT 
        s2.s_suppkey,
        s2.s_name,
        s2.s_acctbal,
        cte.SupplierLevel + 1,
        cte.s_suppkey
    FROM 
        supplier s2
    JOIN 
        SupplierCTE cte ON cte.s_suppkey = s2.s_suppkey
    WHERE 
        s2.s_acctbal < 5000.00
),
AggregatedParts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(ps.ps_suppkey) AS SupplierCount,
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerSegment AS (
    SELECT 
        c.c_mktsegment,
        SUM(o.o_totalprice) AS TotalSales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_mktsegment
),
Marketplace AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(a.SupplierCount, 0) AS SupplierCount,
        a.TotalSupplyCost,
        cs.TotalSales
    FROM 
        part p
    LEFT JOIN 
        AggregatedParts a ON p.p_partkey = a.ps_partkey
    LEFT JOIN 
        CustomerSegment cs ON cs.c_mktsegment = 'BUILDING'
)
SELECT 
    m.p_partkey,
    m.p_name,
    m.p_retailprice,
    m.SupplierCount,
    m.TotalSupplyCost,
    m.TotalSales,
    COALESCE(NULLIF(m.SupplierCount, 0), 1) * m.p_retailprice AS AdjustedPrice,
    ROW_NUMBER() OVER (PARTITION BY m.SupplierCount ORDER BY m.TotalSales DESC) AS SalesRank
FROM 
    Marketplace m
WHERE 
    m.TotalSales IS NOT NULL
ORDER BY 
    m.AdjustedPrice DESC, 
    m.TotalSales DESC;
