WITH processed_parts AS (
    SELECT 
        p.p_partkey,
        UPPER(SUBSTRING(p.p_name, 1, 10)) AS short_name,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(p.p_comment, 'good', 'excellent') AS modified_comment,
        (SELECT COUNT(DISTINCT ps_suppkey) 
         FROM partsupp ps 
         WHERE ps.ps_partkey = p.p_partkey) AS supplier_count
    FROM 
        part p
), customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS total_lineitems
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus
), final_benchmark AS (
    SELECT 
        pp.short_name,
        pp.comment_length,
        pp.modified_comment,
        co.total_lineitems,
        co.o_orderstatus
    FROM 
        processed_parts pp
    JOIN 
        customer_orders co ON pp.supplier_count > 0
    WHERE 
        co.o_orderstatus = 'O'
)
SELECT 
    AVG(comment_length) AS avg_comment_length,
    MAX(total_lineitems) AS max_lineitems,
    COUNT(DISTINCT short_name) AS unique_part_names
FROM 
    final_benchmark;
