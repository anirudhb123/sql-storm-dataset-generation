WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_type AS part_type,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        SUBSTRING(ps.ps_comment, 1, 50) AS truncated_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RegionSupplierDetails AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_list
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    spd.supplier_name,
    spd.part_name,
    spd.part_type,
    spd.available_quantity,
    spd.supply_cost,
    spd.truncated_comment,
    rsd.region_name,
    rsd.total_suppliers,
    rsd.supplier_list
FROM 
    SupplierPartDetails spd
JOIN 
    RegionSupplierDetails rsd ON spd.supplier_name IN (SELECT s_name FROM supplier WHERE s_name IN (SELECT UNNEST(STRING_TO_ARRAY(rsd.supplier_list, ', '))))
ORDER BY 
    spd.part_type, rsd.region_name;
