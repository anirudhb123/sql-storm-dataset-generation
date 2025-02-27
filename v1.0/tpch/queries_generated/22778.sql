WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
HighRetailPriceParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        p.p_retailprice,
        p.p_size
    FROM 
        part p
    WHERE 
        p.p_retailprice = (SELECT MAX(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 50)
),
OrderInfo AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        CASE 
            WHEN SUM(l.l_quantity) = 0 THEN NULL
            ELSE SUM(l.l_extendedprice * (1 - l.l_discount)) / SUM(l.l_quantity)
        END AS avg_price_per_unit
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    H.p_partkey,
    H.p_name,
    H.p_retailprice,
    H.p_size,
    RS.s_name,
    RS.s_acctbal,
    OI.o_orderkey,
    OI.unique_parts,
    OI.total_sales,
    OI.avg_price_per_unit
FROM 
    HighRetailPriceParts H
LEFT JOIN 
    RankedSuppliers RS ON H.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2))
LEFT JOIN 
    OrderInfo OI ON OI.unique_parts > 5 
WHERE 
    H.p_size IS NOT NULL
    AND (H.p_retailprice IS NOT NULL OR OI.total_sales IS NULL)
ORDER BY 
    H.p_retailprice DESC, 
    RS.s_acctbal ASC NULLS LAST;
