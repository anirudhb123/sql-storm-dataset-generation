SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_extendedprice) AS avg_lineitem_price,
    ARRAY_AGG(DISTINCT p.p_name ORDER BY p.p_name) AS product_names,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
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
    r.r_name LIKE 'Eu%' AND 
    o.o_orderdate >= DATE '2022-01-01' AND 
    o.o_orderdate < DATE '2023-01-01'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_revenue DESC, customer_count ASC;
