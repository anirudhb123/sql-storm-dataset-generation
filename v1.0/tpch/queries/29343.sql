WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_supply_cost,
        ss.part_count,
        n.n_name AS nation_name
    FROM 
        SupplierStats ss
    JOIN 
        nation n ON ss.s_nationkey = n.n_nationkey
    WHERE 
        ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    hvs.total_supply_cost,
    hvs.nation_name
FROM 
    RankedParts rp
JOIN 
    HighValueSuppliers hvs ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = hvs.s_suppkey)
WHERE 
    rp.rn <= 5
ORDER BY 
    hvs.total_supply_cost DESC, rp.p_retailprice ASC;
