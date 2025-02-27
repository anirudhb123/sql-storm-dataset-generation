SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderdate AS order_date, 
    COUNT(DISTINCT li.l_orderkey) AS order_count,
    ROUND(SUM(li.l_extendedprice * (1 - li.l_discount)), 2) AS total_revenue,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_involved,
    MAX(CASE 
        WHEN li.l_returnflag = 'R' THEN 'Returned' 
        ELSE 'Not Returned' 
    END) AS return_status
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey AND s.s_suppkey = li.l_suppkey
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%steel%'
    AND o.o_orderdate >= DATE '1996-01-01'
    AND o.o_orderdate < DATE '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderdate
ORDER BY 
    total_revenue DESC
LIMIT 10;