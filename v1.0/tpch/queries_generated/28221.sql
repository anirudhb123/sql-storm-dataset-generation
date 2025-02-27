SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS average_price,
    SUM(CASE 
        WHEN l.l_discount > 0 THEN l.l_extendedprice * l.l_discount 
        ELSE 0 
    END) AS total_discounted_sales,
    SUM(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_quantity 
        ELSE 0 
    END) AS total_returned_items,
    CONCAT(c.c_name, ' from ', SUBSTRING_INDEX(s.s_address, ',', 1)) AS customer_location,
    LPAD(CAST(DATE_FORMAT(o.o_orderdate, '%Y%m') AS CHAR), 6, '0') AS order_month
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
WHERE 
    p.p_retailprice > 25.00
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name
ORDER BY 
    total_orders DESC,
    average_price ASC
LIMIT 50;
