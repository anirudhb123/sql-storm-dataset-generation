WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size >= 10 AND p.p_size <= 20
),
AggregatedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
Results AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        ags.s_suppkey,
        ags.s_name,
        ags.total_supply_value
    FROM 
        RankedParts rp
    JOIN 
        AggregatedSuppliers ags ON rp.p_partkey = (SELECT ps.ps_partkey 
                                                   FROM partsupp ps 
                                                   WHERE ps.ps_suppkey = ags.s_suppkey 
                                                   ORDER BY ps.ps_supplycost DESC LIMIT 1)
    WHERE 
        rp.rank = 1
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.p_brand,
    r.p_retailprice,
    r.s_suppkey,
    r.s_name,
    r.total_supply_value
FROM 
    Results r
ORDER BY 
    r.p_retailprice DESC, r.total_supply_value ASC;
