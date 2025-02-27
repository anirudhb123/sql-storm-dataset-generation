SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_mfgr, 
    s.s_name AS supplier_name, 
    count(distinct c.c_custkey) AS customer_count, 
    sum(l.l_quantity) AS total_quantity_sold,
    avg(o.o_totalprice) AS average_order_value,
    string_agg(distinct r.r_name, ', ') AS regions_served
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_type LIKE '%BRASS%' 
    AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, s.s_name
HAVING 
    total_quantity_sold > 100
ORDER BY 
    average_order_value DESC
LIMIT 10;
