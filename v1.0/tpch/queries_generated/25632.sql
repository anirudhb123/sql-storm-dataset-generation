SELECT 
    p.p_name,
    s.s_name, 
    c.c_name,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment, 
    CONCAT(s.s_name, ' from ', r.r_name) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS avg_extended_price,
    SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * l.l_discount ELSE 0 END) AS total_discounted_price,
    GROUP_CONCAT(DISTINCT CONCAT(c.c_name, ' (', c.c_acctbal, ')') ORDER BY c.c_acctbal DESC) AS customer_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    orders o ON o.o_custkey = c.c_custkey
JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    LENGTH(p.p_name) > 10
AND 
    o.o_orderstatus = 'O'
AND 
    l.l_shipmode IN ('AIR', 'SHIP')
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    avg_extended_price DESC
LIMIT 50;
