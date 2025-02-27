SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(o.o_totalprice) AS average_order_price,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customers,
    CONCAT('Total:', SUM(l.l_extendedprice) * (1 - AVG(l.l_discount))) AS total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_container LIKE 'SMALL%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    short_name, region_name
ORDER BY 
    total_available_quantity DESC, average_order_price ASC;