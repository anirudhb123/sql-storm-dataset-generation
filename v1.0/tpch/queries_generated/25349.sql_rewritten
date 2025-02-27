SELECT 
    p.p_name,
    s.s_name AS supplier_name,
    r.r_name AS region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(c.c_acctbal) AS average_account_balance,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' from ', c.c_address), '; ') AS customer_info,
    MIN(l.l_shipdate) AS first_order_date,
    MAX(l.l_shipdate) AS last_order_date,
    COUNT(*) AS total_orders
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;