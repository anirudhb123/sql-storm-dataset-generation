WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Available Qty: ', ps.ps_availqty, ', Cost: ', ps.ps_supplycost) AS supplier_part_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RegionNations AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS region_nation_info
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    sp.supplier_part_info,
    rn.region_nation_info,
    COUNT(DISTINCT sp.supplier_name) AS distinct_suppliers,
    COUNT(DISTINCT rn.nation_name) AS distinct_nations,
    SUM(sp.available_quantity * sp.supply_cost) AS total_inventory_value
FROM 
    SupplierParts sp
CROSS JOIN 
    RegionNations rn
GROUP BY 
    sp.supplier_part_info, rn.region_nation_info
ORDER BY 
    total_inventory_value DESC;
