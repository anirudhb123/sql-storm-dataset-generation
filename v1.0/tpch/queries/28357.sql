SELECT 
    p.p_name,
    CONCAT(s.s_name, ' - ', p.p_type) AS supplier_part_info,
    SUM(l.l_quantity) AS total_quantity,
    AVG(CAST(l.l_extendedprice AS DECIMAL(12,2))) AS avg_price,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' (', c.c_acctbal, ')'), ', ') AS customer_list,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_comment LIKE '%premium%'
GROUP BY 
    p.p_name, supplier_part_info, r.r_name
ORDER BY 
    total_quantity DESC, avg_price DESC;