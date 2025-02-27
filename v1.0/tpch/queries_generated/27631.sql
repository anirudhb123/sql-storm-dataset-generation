WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        CHAR_LENGTH(p.p_comment) > 15
),
TopItems AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.ps_supplycost,
        n.n_name,
        r.r_name,
        CONCAT(n.n_name, ' - ', r.r_name) AS nation_region
    FROM 
        RankedParts rp
    JOIN 
        supplier s ON rp.p_partkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rp.rn <= 5
)
SELECT 
    t.p_partkey,
    t.p_name,
    t.p_mfgr,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    STRING_AGG(t.nation_region, ', ') AS regions_supplied
FROM 
    TopItems t
JOIN 
    lineitem l ON t.p_partkey = l.l_partkey
GROUP BY 
    t.p_partkey, t.p_name, t.p_mfgr
ORDER BY 
    total_quantity DESC
LIMIT 10;
