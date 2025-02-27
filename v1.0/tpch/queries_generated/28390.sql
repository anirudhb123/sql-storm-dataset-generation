SELECT 
    CONCAT(s.s_name, ' from ', c.c_name, ' (', c.c_acctbal, ')') AS supplier_customer_info,
    STRING_AGG(DISTINCT CONCAT('Order #', o.o_orderkey, ' with total price ', o.o_totalprice), ', ') AS order_details,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date,
    RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
WHERE 
    c.c_mktsegment = 'BUILDING'
    AND s.s_comment LIKE '%reliable%'
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    s.s_suppkey, c.c_custkey
ORDER BY 
    sales_rank;
