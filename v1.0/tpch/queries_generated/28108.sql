SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_avail_qty, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    AVG(o.o_totalprice) AS avg_order_price, 
    STRING_AGG(DISTINCT SUBSTRING(o.o_comment FROM 1 FOR 30) || '...', ', ') AS order_comments, 
    r.r_name AS region_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 50.00 AND 
    o.o_orderstatus = 'O' AND 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name
HAVING 
    total_avail_qty > 100
ORDER BY 
    total_avail_qty DESC, avg_order_price ASC;
