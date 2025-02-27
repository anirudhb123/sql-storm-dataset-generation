WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS PriceRank
    FROM 
        part p
    WHERE 
        p.p_size IS NOT NULL
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COALESCE(MAX(s.s_acctbal), 0) AS MaxAccountBalance,
        COUNT(DISTINCT ps.ps_partkey) AS SuppliedParts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighPriceItems AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice
    FROM 
        RankedParts rp
    WHERE 
        rp.PriceRank <= 3
)
SELECT 
    c.c_name,
    COALESCE(STRING_AGG(DISTINCT hi.p_name, ', ') FILTER (WHERE hi.p_name IS NOT NULL), 'No Parts') AS HighPricePartNames,
    ss.MaxAccountBalance,
    SUM(CASE 
        WHEN oi.nationkey IS NULL THEN 0 
        ELSE oi.price 
    END) AS OrderTotalPrice
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    (SELECT 
         l.l_orderkey, 
         SUM(l.l_extendedprice * (1 - l.l_discount)) AS price, 
         l.l_orderkey AS order_key
     FROM 
         lineitem l
     GROUP BY 
         l.l_orderkey) oi ON o.o_orderkey = oi.order_key
LEFT JOIN 
    HighPriceItems hi ON hi.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost > 0)
LEFT JOIN 
    SupplierStats ss ON ss.s_supplied_parts = (SELECT COUNT(*) FROM partsupp WHERE ps.ps_supplycost > 0)
GROUP BY 
    c.c_name, ss.MaxAccountBalance
HAVING 
    SUM(CASE WHEN c.c_acctbal IS NULL THEN 1 ELSE 0 END) = 0
    AND COALESCE(MAX(hi.p_retailprice), 0) > (
        SELECT AVG(p.p_retailprice) FROM part p WHERE p.p_container LIKE 'SM%'
    )
ORDER BY 
    ss.MaxAccountBalance DESC;
