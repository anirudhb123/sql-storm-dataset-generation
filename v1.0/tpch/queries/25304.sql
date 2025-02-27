WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        COUNT(ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        STRING_AGG(ps.ps_comment, '; ') AS aggregated_comments
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_type,
        rp.p_size,
        rp.supplier_count,
        rp.avg_supply_cost,
        rp.aggregated_comments,
        RANK() OVER (PARTITION BY rp.p_brand ORDER BY rp.avg_supply_cost DESC) AS rank_within_brand
    FROM 
        RankedParts rp
    WHERE 
        rp.supplier_count > 5
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_brand,
    fp.p_type,
    fp.p_size,
    fp.avg_supply_cost,
    fp.aggregated_comments
FROM 
    FilteredParts fp
WHERE 
    fp.rank_within_brand <= 5
ORDER BY 
    fp.p_brand, fp.avg_supply_cost DESC;
