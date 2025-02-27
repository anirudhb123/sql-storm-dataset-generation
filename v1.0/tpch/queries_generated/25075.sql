SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')') ORDER BY s.s_name SEPARATOR ', '), ',', 5) AS suppliers_list,
    TRIM(TRAILING ' ' FROM GROUP_CONCAT(DISTINCT p.p_comment ORDER BY p.p_comment SEPARATOR '; ')) AS part_comments
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
WHERE 
    p.p_type LIKE '%brass%' 
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, s.s_suppkey, c.c_custkey, o.o_orderkey
ORDER BY 
    total_revenue DESC, last_ship_date DESC
LIMIT 10;
