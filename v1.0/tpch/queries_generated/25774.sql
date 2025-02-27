WITH CombinedData AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderkey AS order_key,
        l.l_quantity AS quantity,
        l.l_extendedprice AS extended_price,
        l.l_discount AS discount,
        l.l_tax AS tax,
        SUBSTRING(s.s_comment, 1, 20) AS short_supplier_comment,
        CONCAT(c.c_name, ' - ', c.c_address) AS customer_info,
        CONCAT('Order ID: ', o.o_orderkey, ', Priority: ', o.o_orderpriority) AS order_details
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    part_name,
    supplier_name,
    COUNT(*) AS total_orders,
    SUM(quantity) AS total_quantity,
    SUM(extended_price) AS total_extended_price,
    AVG(discount) AS average_discount,
    SUM(tax) AS total_tax,
    STRING_AGG(DISTINCT short_supplier_comment, '; ') AS supplier_comments,
    STRING_AGG(DISTINCT customer_info, '; ') AS customer_details,
    STRING_AGG(DISTINCT order_details, '; ') AS order_information
FROM 
    CombinedData
GROUP BY 
    part_name, supplier_name
ORDER BY 
    total_extended_price DESC
LIMIT 10;
