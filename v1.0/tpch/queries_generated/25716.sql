SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_number,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    RANK() OVER (PARTITION BY p.p_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    CASE 
        WHEN o.o_orderstatus = 'O' THEN 'Open'
        WHEN o.o_orderstatus = 'F' THEN 'Finished'
        ELSE 'Unknown'
    END AS order_status,
    SUBSTRING(p.p_comment FROM 1 FOR 10) AS brief_comment
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_type LIKE '%metal%'
    AND o.o_orderdate >= DATE '2023-01-01'
    AND o.o_orderdate < DATE '2024-01-01'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderstatus
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC, order_number ASC
LIMIT 50;
