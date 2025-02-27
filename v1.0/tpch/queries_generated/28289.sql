WITH string_benchmark AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderdate AS order_date,
        CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name, ', Date: ', o.o_orderdate) AS full_description
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE LENGTH(p.p_name) > 10 AND LENGTH(s.s_name) > 5
)
SELECT 
    SUBSTRING(full_description, 1, 50) AS short_description,
    UPPER(SUBSTRING(part_name, 1, 10)) AS upper_part_name,
    LOWER(SUBSTRING(supplier_name, 1, 10)) AS lower_supplier_name,
    LENGTH(full_description) AS description_length
FROM string_benchmark
WHERE full_description LIKE '%Customer%'
ORDER BY description_length DESC;
