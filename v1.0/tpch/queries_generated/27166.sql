SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_avail_qty,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' (', c.c_acctbal, ')'), '; ') AS customer_details,
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name) AS supplier_region_info,
    COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS returns_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 100.00
GROUP BY 
    p.p_name, s.s_name, r.r_name
HAVING 
    SUM(ps.ps_availqty) > 50
ORDER BY 
    total_avail_qty DESC, p.p_name;
