
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) as supplier_count,
        SUM(ps.ps_availqty) as total_avail_qty,
        AVG(ps.ps_supplycost) as avg_supply_cost,
        LISTAGG(DISTINCT s.s_name, ', ') AS suppliers_list
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type
),
FilteredParts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (PARTITION BY rp.p_mfgr ORDER BY rp.total_avail_qty DESC) AS part_rank
    FROM 
        RankedParts rp
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_mfgr,
    fp.p_brand,
    fp.p_type,
    fp.supplier_count,
    fp.total_avail_qty,
    ROUND(fp.avg_supply_cost, 2) AS rounded_avg_supply_cost,
    fp.suppliers_list
FROM 
    FilteredParts fp
WHERE 
    fp.part_rank <= 5
ORDER BY 
    fp.p_mfgr, 
    fp.total_avail_qty DESC;
