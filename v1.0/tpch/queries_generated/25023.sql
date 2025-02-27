SELECT 
    s.s_name AS supplier_name,
    SUBSTRING(s.s_address, 1, 15) AS short_address,
    c.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(CASE 
            WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE l.l_extendedprice 
        END) AS avg_price_after_discount,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_partkey, ')'), ', ') AS parts_supplied,
    r.r_name AS region_name
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'S%'
GROUP BY 
    s.s_name, short_address, c.c_name, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_revenue DESC
LIMIT 50;
