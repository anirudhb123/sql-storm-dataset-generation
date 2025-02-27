
SELECT 
    p.p_name, 
    SUBSTRING(p.p_comment, 1, 20) AS short_comment, 
    CONCAT('Supplier Name: ', s.s_name, ', Address: ', s.s_address) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(l.l_tax) AS max_tax,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    (SELECT COUNT(*) FROM customer c WHERE c.c_nationkey = n.n_nationkey) AS customers_count
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
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size > 10 AND 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_comment, s.s_name, s.s_address, n.n_nationkey
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    avg_price DESC
LIMIT 10;
