WITH SupplierStatistics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 5
)
SELECT 
    s.s_name,
    s.nation_name,
    s.part_count,
    s.total_supply_cost,
    CASE 
        WHEN s.total_supply_cost > 1000 THEN 'High Supplier'
        WHEN s.total_supply_cost BETWEEN 500 AND 1000 THEN 'Medium Supplier'
        ELSE 'Low Supplier'
    END AS supplier_category,
    s.part_names
FROM 
    SupplierStatistics s
ORDER BY 
    s.total_supply_cost DESC;
