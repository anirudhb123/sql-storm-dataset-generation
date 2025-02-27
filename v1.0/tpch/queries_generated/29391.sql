WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        p.p_comment AS part_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RichSuppliers AS (
    SELECT 
        supplier_name,
        SUM(available_quantity * supply_cost) AS total_supply_value,
        STRING_AGG(part_name, ', ') AS supplied_parts,
        MAX(part_comment) AS most_commented_part
    FROM 
        SupplierParts
    GROUP BY 
        supplier_name
    HAVING 
        SUM(available_quantity * supply_cost) > 50000
),
FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.supplier_name,
        rs.total_supply_value,
        rs.supplied_parts,
        rs.most_commented_part
    FROM 
        RichSuppliers rs
    JOIN 
        supplier s ON rs.supplier_name = s.s_name
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    region_name,
    nation_name,
    supplier_name,
    FORMAT(total_supply_value, 'C', 'en-US') AS total_supply_value,
    supplied_parts,
    most_commented_part
FROM 
    FinalReport
ORDER BY 
    region_name, nation_name, total_supply_value DESC;
