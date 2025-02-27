
WITH supplier_info AS (
    SELECT 
        s_name,
        s_acctbal,
        REPLACE(s_comment, 'bad', 'good') AS adjusted_comment,
        CONCAT('Supplier: ', s_name, ', Balance: ', CAST(s_acctbal AS CHAR(15)), ', Note: ', REPLACE(s_comment, 'bad', 'good')) AS full_info
    FROM 
        supplier
),
customer_order_summary AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS average_order_value,
        STRING_AGG(DISTINCT CONCAT(o.o_orderstatus, ' ', o.o_orderpriority), ', ') AS order_status_summary
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    s.s_name,
    AVG(cos.total_spent) AS average_customer_spent,
    COUNT(DISTINCT cos.c_name) AS unique_customers,
    STRING_AGG(DISTINCT cos.order_status_summary, '; ') AS order_overview,
    COUNT(DISTINCT p.p_name) AS unique_parts_supplied,
    s_info.full_info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier_info s_info ON s.s_name = s_info.s_name
JOIN 
    customer_order_summary cos ON cos.c_name = s_info.adjusted_comment
WHERE 
    s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
GROUP BY 
    s.s_name, s_info.full_info;
