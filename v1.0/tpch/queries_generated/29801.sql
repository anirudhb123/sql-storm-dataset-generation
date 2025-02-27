WITH SupplierInfo AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        CONCAT(s.s_name, ' from ', (SELECT n.n_name FROM nation n WHERE n.n_nationkey = s.s_nationkey)) AS full_supplier_info,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(l.l_quantity) AS total_quantity_sold,
        MIN(l.l_discount) AS min_discount,
        MAX(l.l_discount) AS max_discount,
        STRING_AGG(DISTINCT l.l_shipmode, ', ') AS ship_modes_used
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
)
SELECT 
    si.full_supplier_info,
    pi.p_name,
    pi.total_quantity_sold,
    pi.min_discount,
    pi.max_discount,
    pi.ship_modes_used
FROM 
    SupplierInfo si
JOIN 
    PartInfo pi ON si.parts_supplied > 0
ORDER BY 
    pi.total_quantity_sold DESC, 
    si.total_supply_cost DESC;
