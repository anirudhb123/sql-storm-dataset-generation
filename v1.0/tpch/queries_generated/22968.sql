WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS PriceRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1995-01-01'
        AND o.o_orderstatus IN ('O', 'F')
), 
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
HighValueLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        (l.l_extendedprice * (1 - l.l_discount)) AS NetPrice
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1996-01-01' AND '1997-12-31'
        AND l.l_discount BETWEEN 0.05 AND 0.10
), 
SupplierPart AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount,
        AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM 
        supplier s
    JOIN 
        PartSupplier ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
        AND s.s_acctbal > (
            SELECT AVG(s_acctbal) FROM supplier WHERE s_regionkey IS NULL
        )
    GROUP BY 
        s.s_name, s.s_nationkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(AVG(hl.NetPrice), 0) AS AvgNetPrice,
    COALESCE(r.SumPrices, 0) AS SumPrices,
    sr.PartCount,
    CASE
        WHEN sr.PartCount > 5 THEN 'High Supply'
        ELSE 'Low Supply'
    END AS SupplyCategory
FROM 
    part p
LEFT JOIN 
    HighValueLineItems hl ON p.p_partkey = hl.l_partkey
LEFT JOIN 
    (SELECT 
         o.o_orderkey, SUM(o.o_totalprice) AS SumPrices
     FROM 
         RankedOrders o
     WHERE 
         o.PriceRank <= 10
     GROUP BY 
         o.o_orderkey
    ) r ON r.o_orderkey = hl.l_orderkey
LEFT JOIN 
    SupplierPart sr ON sr.s_nationkey = p.p_mfgr
GROUP BY 
    p.p_partkey, p.p_name, sr.PartCount, r.SumPrices
HAVING 
    SUM(hl.l_quantity) IS NULL OR SUM(hl.l_quantity) > 100
ORDER BY 
    AvgNetPrice DESC NULLS LAST;
