
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        CONCAT('Manufacturer ',
               SUBSTR(p.p_mfgr, 1, 5), '...',
               ' with type ',
               SUBSTR(p.p_type, 1, 10), '...') AS part_description,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_container LIKE 'SM%'
),
AggregatedData AS (
    SELECT 
        np.n_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT sp.s_suppkey) AS unique_suppliers,
        LISTAGG(DISTINCT rp.part_description, '; ') WITHIN GROUP (ORDER BY rp.part_description) AS part_summaries
    FROM 
        nation np
    JOIN 
        supplier sp ON np.n_nationkey = sp.s_nationkey
    JOIN 
        partsupp ps ON sp.s_suppkey = ps.ps_suppkey
    JOIN 
        RankedParts rp ON ps.ps_partkey = rp.p_partkey
    WHERE 
        rp.rnk <= 10
    GROUP BY 
        np.n_name
)
SELECT 
    ad.n_name AS nation_name,
    ad.total_supply_value,
    ad.unique_suppliers,
    ad.part_summaries
FROM 
    AggregatedData ad
WHERE 
    ad.total_supply_value > 100000
ORDER BY 
    ad.total_supply_value DESC;
