WITH Combined AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        CONCAT(s.s_address, ', ', s.s_phone) AS supplier_details,
        c.c_name AS customer_name,
        CONCAT(c.c_address, ', ', c.c_phone) AS customer_details,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        supplier_name, part_name, supplier_details, customer_name, customer_details
)
SELECT 
    supplier_name,
    part_name,
    supplier_details,
    customer_name,
    customer_details,
    total_price,
    CASE 
        WHEN total_price > 1000 THEN 'High Value'
        WHEN total_price BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS price_category
FROM 
    Combined
WHERE 
    total_price > (SELECT AVG(total_price) FROM Combined)
ORDER BY 
    total_price DESC;
