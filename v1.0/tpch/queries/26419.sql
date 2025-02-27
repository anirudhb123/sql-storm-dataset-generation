SELECT 
    CONCAT('Part: ', p.p_name, ' | Provider: ', s.s_name, ' | Region: ', r.r_name) AS item_details,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(s.s_acctbal) AS average_supplier_balance,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
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
    p.p_container IN ('SM CASE', 'SM BOX')
    AND r.r_name = 'ASIA'
    AND o.o_orderdate >= '1996-01-01'
GROUP BY 
    p.p_name, s.s_name, r.r_name
ORDER BY 
    total_sales DESC;