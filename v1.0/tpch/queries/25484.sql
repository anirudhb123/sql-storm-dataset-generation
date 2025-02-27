WITH StringAggregates AS (
    SELECT 
        p.p_type,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_acctbal, ')'), '; ') AS suppliers_list
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_type
),
StringFilters AS (
    SELECT 
        p_type,
        supplier_count,
        total_available_quantity,
        suppliers_list
    FROM StringAggregates
    WHERE supplier_count > 5 AND total_available_quantity > 1000
)
SELECT 
    p_type,
    supplier_count,
    total_available_quantity,
    suppliers_list,
    LENGTH(suppliers_list) AS suppliers_list_length,
    REPLACE(suppliers_list, ';', ', ') AS suppliers_list_comma_separated
FROM StringFilters
ORDER BY total_available_quantity DESC;
