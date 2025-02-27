
WITH StringBenchmark AS (
    SELECT 
        p.p_partkey,
        COUNT(*) AS part_count,
        STRING_AGG(DISTINCT s.s_name, '; ' ORDER BY s.s_name) AS supplier_names,
        MAX(LENGTH(p.p_name)) AS max_part_name_length,
        MIN(LENGTH(p.p_comment)) AS min_part_comment_length,
        AVG(LENGTH(s.s_comment)) AS avg_supplier_comment_length,
        STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    part_count,
    MAX(max_part_name_length) AS max_length_of_part_name,
    MIN(min_part_comment_length) AS min_length_of_part_comment,
    AVG(avg_supplier_comment_length) AS average_length_of_supplier_comment,
    STRING_AGG(DISTINCT supplier_names, '| ') AS all_supplier_names
FROM 
    StringBenchmark
WHERE 
    part_count > 5
GROUP BY 
    part_count;
