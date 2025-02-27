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
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.r_name,
    n.n_name,
    sp.s_name,
    rp.p_name,
    rp.price_rank,
    ss.total_availability,
    ss.avg_supply_cost
FROM 
    RankedParts rp
JOIN 
    SupplierStats ss ON ss.unique_parts_supplied > 5 
JOIN 
    supplier sp ON ss.s_suppkey = sp.s_suppkey
JOIN 
    nation n ON sp.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rp.price_rank <= 3
ORDER BY 
    r.r_name, n.n_name, rp.p_name;
