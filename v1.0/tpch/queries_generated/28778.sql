WITH StringAnalysis AS (
    SELECT 
        s.s_name AS supplier_name,
        LENGTH(s.s_name) AS name_length,
        SUBSTRING_INDEX(s.s_name, ' ', -1) AS last_name,
        COUNT(DISTINCT p.p_partkey) AS product_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        GROUP_CONCAT(DISTINCT p.p_name ORDER BY p.p_name SEPARATOR ', ') AS product_names,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS nation_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        supplier_name,
        name_length,
        last_name,
        product_count,
        total_available_quantity,
        total_supply_cost,
        product_names,
        nation_rank
    FROM 
        StringAnalysis
    WHERE 
        nation_rank <= 5
)
SELECT 
    supplier_name,
    name_length,
    last_name,
    product_count,
    total_available_quantity,
    total_supply_cost,
    product_names
FROM 
    TopSuppliers
ORDER BY 
    total_supply_cost DESC, name_length ASC;
