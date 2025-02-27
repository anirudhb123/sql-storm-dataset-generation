SELECT 
    p.p_name,
    s.s_name,
    r.r_name AS region_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_supplier_account_balance,
    COUNT(DISTINCT c.c_custkey) AS total_customers_related,
    STRING_AGG(DISTINCT o.o_orderstatus, ', ') AS unique_order_statuses,
    MAX(o.o_totalprice) AS max_order_total_price
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
    p.p_brand LIKE '%Brand%'
    AND s.s_comment LIKE '%premium%'
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    average_supplier_account_balance DESC, total_available_quantity DESC;
