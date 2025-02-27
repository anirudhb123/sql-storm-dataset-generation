WITH StringAggregates AS (
    SELECT 
        CONCAT('Supplier: ', s_name, ' | Address: ', s_address, ' | Nation: ', n_name) AS supplier_info,
        LENGTH(s_name) + LENGTH(s_address) + LENGTH(n_name) AS total_length,
        SUM(CASE WHEN ps_supplycost > 100 THEN 1 ELSE 0 END) AS high_cost_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.suppkey, s.s_name, s.s_address, n.n_name
),
FilteredAggregates AS (
    SELECT 
        supplier_info,
        total_length,
        high_cost_parts
    FROM 
        StringAggregates
    WHERE 
        total_length > 100
)
SELECT 
    supplier_info,
    total_length,
    high_cost_parts,
    CASE 
        WHEN high_cost_parts >= 5 THEN 'High supplier activity'
        WHEN high_cost_parts BETWEEN 1 AND 4 THEN 'Medium supplier activity'
        ELSE 'Low supplier activity'
    END AS activity_level
FROM 
    FilteredAggregates
ORDER BY 
    total_length DESC;
