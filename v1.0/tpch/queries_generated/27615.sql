SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price, 
    STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', s.s_comment), '; ') AS nation_comments
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem AS l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer AS c ON o.o_custkey = c.c_custkey
JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    c.c_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_orders DESC, 
    avg_price ASC;
