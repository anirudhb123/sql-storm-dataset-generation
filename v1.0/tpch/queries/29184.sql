
SELECT 
    p.p_name, 
    CONCAT(s.s_name, ' (', s.s_address, ', ', n.n_name, ')') AS supplier_info, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    MAX(o.o_orderdate) AS last_order_date
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
    n.n_name LIKE 'A%' AND 
    o.o_orderstatus = 'F' AND 
    o.o_orderdate > '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, s.s_address, n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    MAX(o.o_orderdate) DESC, SUM(l.l_extendedprice * (1 - l.l_discount)) DESC;
