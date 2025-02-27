SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    STRING_AGG(DISTINCT LOWER(CONCAT('Order Key: ', o.o_orderkey, ' - Order Date: ', o.o_orderdate, ' - Status: ', o.o_orderstatus)), '; ') AS order_details
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%widget%'
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND s.s_acctbal > 1000.00
GROUP BY 
    p.p_name, s.s_name, r.r_name
ORDER BY 
    total_quantity DESC;