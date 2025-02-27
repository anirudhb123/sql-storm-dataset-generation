WITH StringProcessing AS (
    SELECT 
        p.p_name,
        s.s_name,
        c.c_name,
        o.o_orderkey,
        REPLACE(REPLACE(p.p_comment, 'old', 'new'), 'unwanted', 'desired') AS processed_comment,
        CONCAT('Supplier: ', s.s_name, ', Customer: ', c.c_name) AS supplier_customer_info,
        SUBSTRING(o.o_orderdate, 1, 7) AS order_month,
        COUNT(DISTINCT l.l_orderkey) AS total_orders,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    order_month, 
    COUNT(DISTINCT o_orderkey) AS unique_orders,
    AVG(total_quantity) AS avg_quantity_per_order,
    STRING_AGG(DISTINCT processed_comment, '; ') AS all_processed_comments,
    STRING_AGG(DISTINCT supplier_customer_info, '; ') AS all_supplier_customer_info
FROM 
    StringProcessing
GROUP BY 
    order_month
ORDER BY 
    order_month;
