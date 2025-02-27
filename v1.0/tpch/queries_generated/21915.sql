WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1994-01-01' AND CURRENT_DATE
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as SupplierRank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_comment IS NOT NULL)
),
PartsOffering AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        (SELECT SUM(ps.ps_supplycost) 
         FROM partsupp ps 
         WHERE ps.ps_partkey = p.p_partkey) as TotalSupplyCost
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
QuantitySummary AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS TotalQuantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > '1995-01-01'
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_name,
    COUNT(DISTINCT o.o_orderkey) AS OrderCount,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END) AS TotalReturned,
    COUNT(DISTINCT CASE WHEN l.l_discount > 0 THEN l.l_orderkey END) AS DiscountedOrders,
    MAX(rs.TotalSupplyCost) AS MaxSupplyCost,
    SUM(COALESCE(qs.TotalQuantity, 0)) AS TotalQuantitySold,
    r.r_name AS RegionName
FROM 
    PartsOffering p
LEFT JOIN 
    RankedOrders o ON o.o_orderkey IN (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_partkey = p.p_partkey
    )
LEFT JOIN 
    FilteredSuppliers s ON s.s_suppkey IN (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey = p.p_partkey
    )
LEFT JOIN 
    QuantitySummary qs ON qs.l_partkey = p.p_partkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_totalprice IS NOT NULL OR s.s_comment NOT LIKE '%%NULL%'
GROUP BY 
    p.p_name, r.r_name
HAVING 
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) > 10
ORDER BY 
    OrderCount DESC, TotalQuantitySold DESC;
