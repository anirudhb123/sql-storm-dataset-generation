
WITH StringProcessing AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nation_names,
        LENGTH(p.p_comment) AS comment_length,
        p.p_comment AS part_comment,
        CONCAT('Supplier: ', s.s_name, ' | Customer: ', c.c_name) AS details
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        p.p_name, s.s_name, c.c_name, p.p_comment
    HAVING 
        LENGTH(p.p_comment) > 20
)
SELECT 
    part_name,
    supplier_name,
    customer_name,
    order_count,
    nation_names,
    details
FROM 
    StringProcessing
WHERE 
    order_count > 5
ORDER BY 
    order_count DESC, part_name;
