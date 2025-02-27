WITH supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS supplier_nation,
        r.r_name AS supplier_region,
        CONCAT(s.s_name, ' (', n.n_name, ', ', r.r_name, ')') AS supplier_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
product_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers_list
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.p_brand,
    ps.total_available_quantity,
    ps.avg_supply_cost,
    sd.supplier_info,
    ps.suppliers_list
FROM 
    product_summary ps
JOIN 
    supplier_details sd ON sd.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ps.p_partkey)
ORDER BY 
    ps.total_available_quantity DESC, ps.avg_supply_cost ASC;
