SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS latest_shipdate,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', s.s_address, ' (', s.s_phone, ')'), '; ') AS suppliers_info
FROM 
    supplier s
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    s.s_name, p.p_name
ORDER BY 
    total_revenue DESC, customer_count DESC;