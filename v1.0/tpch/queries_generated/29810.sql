SELECT 
    p.p_name,
    s.s_name,
    CONCAT(s.s_address, ', ', n.n_name, ' (Nation Key: ', s.s_nationkey, ')') AS supplier_location,
    SUM(ps.ps_availqty * (l.l_extendedprice * (1 - l.l_discount))) AS total_value,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    SUBSTRING(p.p_comment, 1, 30) AS short_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_type LIKE '%metal%'
    AND o.o_orderdate >= DATE '2022-01-01'
    AND o.o_orderdate < DATE '2023-01-01'
GROUP BY 
    p.p_name, s.s_name, s.s_nationkey, s.s_address, p.p_comment
HAVING 
    SUM(ps.ps_availqty * (l.l_extendedprice * (1 - l.l_discount))) > 10000
ORDER BY 
    total_value DESC;
