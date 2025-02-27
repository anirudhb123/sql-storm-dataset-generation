WITH StringBenchmark AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        CONCAT(p.p_name, ' - ', s.s_name, ' - ', c.c_name) AS combined_string,
        LENGTH(CONCAT(p.p_name, ' - ', s.s_name, ' - ', c.c_name)) AS string_length,
        REPLACE(CONCAT(p.p_name, ' - ', s.s_name, ' - ', c.c_name), ' ', '') AS no_space_string,
        UPPER(SUBSTRING(c.c_name, 1, 5)) AS customer_upper,
        LEFT(p.p_name, 10) AS part_name_short
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON c.c_custkey IN (
            SELECT o.o_custkey
            FROM orders o
            JOIN lineitem l ON o.o_orderkey = l.l_orderkey
            WHERE l.l_partkey = p.p_partkey
        )
    WHERE 
        p.p_size > 10
)
SELECT 
    AVG(string_length) AS avg_string_length,
    COUNT(DISTINCT part_name) AS unique_parts,
    COUNT(DISTINCT supplier_name) AS unique_suppliers,
    COUNT(DISTINCT customer_name) AS unique_customers,
    MAX(string_length) AS max_length,
    MIN(string_length) AS min_length
FROM 
    StringBenchmark;
