SELECT 
    CONCAT('Supplier ', s_name, ' from nation ', n_name, ' supplies the part ', p_name, ' of type ', p_type, 
           ' in a ', p_container, ' container priced at ', FORMAT(p_retailprice, 2), 
           '. Additional comments: ', p_comment) AS detailed_description,
    COUNT(DISTINCT c_custkey) AS total_customers,
    AVG(o_totalprice) AS average_order_value,
    SUM(CASE WHEN l_returnflag = 'Y' THEN 1 ELSE 0 END) AS total_returns,
    r_name AS region_name
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p_size > 10 
    AND o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    s.suppkey, p.p_partkey, n.n_nationkey, r.r_regionkey
HAVING 
    AVG(o_totalprice) > 100
ORDER BY 
    region_name DESC, total_customers DESC;
