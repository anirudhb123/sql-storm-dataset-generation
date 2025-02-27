WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_comment,
        CONCAT(s.s_name, ' supplies ', p.p_name) AS supply_description
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), AggregatedData AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT sp.s_suppkey) AS supplier_count,
        SUM(sp.ps_availqty) AS total_available_quantity,
        AVG(sp.ps_supplycost) AS average_supply_cost,
        STRING_AGG(sp.supply_description, '; ') AS supplier_part_descriptions
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierParts sp ON s.s_suppkey = sp.s_suppkey
    GROUP BY 
        r.r_name
)
SELECT 
    r_name,
    supplier_count,
    total_available_quantity,
    average_supply_cost,
    supplier_part_descriptions
FROM 
    AggregatedData
WHERE 
    supplier_count > 5
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
