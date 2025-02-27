
SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_availqty) AS average_available_quantity,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    MAX(o.o_totalprice) AS max_order_price,
    LENGTH(ps.ps_comment) AS comment_length
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_retailprice > 100.00 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, ps.ps_availqty, ps.ps_comment
HAVING 
    AVG(ps.ps_supplycost) < 200.00
ORDER BY 
    supplier_count DESC, max_order_price DESC;
