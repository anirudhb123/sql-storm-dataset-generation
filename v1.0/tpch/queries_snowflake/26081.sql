
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_avail_qty,
        LISTAGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS suppliers_list
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
),
FilteredParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name,
        rp.supplier_count, 
        rp.avg_supply_cost,
        rp.total_avail_qty,
        rp.suppliers_list
    FROM 
        RankedParts rp
    WHERE 
        rp.supplier_count > 10 AND 
        rp.avg_supply_cost < (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
)
SELECT 
    fp.p_partkey, 
    fp.p_name, 
    fp.supplier_count, 
    fp.avg_supply_cost, 
    fp.total_avail_qty, 
    fp.suppliers_list,
    ROW_NUMBER() OVER (ORDER BY fp.total_avail_qty DESC) AS rank
FROM 
    FilteredParts fp
ORDER BY 
    fp.total_avail_qty DESC,
    fp.avg_supply_cost ASC
LIMIT 100;
