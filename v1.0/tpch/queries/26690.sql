WITH StringBenchmark AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderdate AS order_date,
        CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name) AS combined_info,
        LENGTH(CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name)) AS combined_length,
        SUBSTRING(p.p_comment, 1, 10) AS part_comment_excerpt,
        LEFT(s.s_comment, 20) AS supplier_comment_excerpt,
        REGEXP_REPLACE(c.c_comment, '[^a-zA-Z0-9 ]', '') AS cleaned_customer_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        orders o ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = s.s_nationkey LIMIT 1)
    JOIN 
        customer c ON c.c_nationkey = s.s_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    ORDER BY 
        combined_length DESC
)
SELECT 
    part_name, 
    supplier_name, 
    customer_name, 
    order_date, 
    combined_info, 
    combined_length, 
    part_comment_excerpt, 
    supplier_comment_excerpt, 
    cleaned_customer_comment
FROM 
    StringBenchmark
LIMIT 100;