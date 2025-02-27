WITH StringAggregation AS (
    SELECT 
        s.s_name AS supplier_name,
        STRING_AGG(CONCAT(p.p_name, ': ', ps.ps_supplycost), ', ') AS parts_info
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_name
),
FilteredSuppliers AS (
    SELECT 
        supplier_name, 
        parts_info
    FROM StringAggregation
    WHERE LENGTH(parts_info) > 100
)
SELECT 
    supplier_name, 
    parts_info,
    LENGTH(parts_info) AS info_length
FROM FilteredSuppliers
ORDER BY info_length DESC;
