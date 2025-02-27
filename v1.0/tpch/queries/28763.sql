SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    COUNT(l.l_orderkey) AS lineitem_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS average_quantity,
    MAX(l.l_shipdate) AS latest_shipdate,
    MIN(l.l_receiptdate) AS earliest_receiptdate,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ' (', r.r_name, ')'), ', ') AS nations_regions
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
    p.p_retailprice > 20.00 AND 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
HAVING 
    COUNT(l.l_orderkey) > 5
ORDER BY 
    total_revenue DESC;