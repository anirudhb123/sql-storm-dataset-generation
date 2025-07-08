
WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        LENGTH(p.p_comment) AS comment_length,
        CONCAT(s.s_name, ' - ', p.p_name) AS supplier_part_combo
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
RegionSupplierCount AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ps.p_partkey) AS part_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUM(ps.ps_availqty) AS total_avail_qty,
    MAX(ps.comment_length) AS max_comment_length,
    LISTAGG(DISTINCT ps.supplier_part_combo, '; ') WITHIN GROUP (ORDER BY ps.supplier_part_combo) AS supplier_part_list
FROM 
    PartSupplierDetails ps
JOIN 
    RegionSupplierCount r ON ps.supplier_name IN (SELECT s.s_name FROM supplier s WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.n_regionkey))
GROUP BY 
    r.r_name
ORDER BY 
    part_count DESC;
