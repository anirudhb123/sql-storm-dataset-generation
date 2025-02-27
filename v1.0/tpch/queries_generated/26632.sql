WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        LENGTH(s.s_comment) AS comment_length,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_nationkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_nationkey,
        c.c_mktsegment,
        LENGTH(c.c_comment) AS comment_length,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address, c.c_nationkey, c.c_mktsegment
)
SELECT 
    s.s_name AS supplier_name,
    s.s_address AS supplier_address,
    c.c_name AS customer_name,
    c.c_address AS customer_address,
    s.comment_length AS supplier_comment_length,
    c.comment_length AS customer_comment_length,
    COALESCE(c.total_spent, 0) AS customer_total_spent,
    s.part_count AS supplier_part_count
FROM 
    SupplierDetails s
JOIN 
    CustomerDetails c ON s.s_nationkey = c.c_nationkey
WHERE 
    s.comment_length > 50 
    AND c.total_spent > 1000
ORDER BY 
    supplier_name, customer_name;
