SELECT 
    CONCAT(c.c_name, ' from ', s.s_name, ' located at ', s.s_address) AS supplier_customer_details,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    MAX(o.o_orderdate) AS last_order_date
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    c.c_acctbal > 1000 AND 
    l.l_returnflag = 'N' AND 
    o.o_orderstatus IN ('F', 'O')
GROUP BY 
    c.c_name, s.s_name, s.s_address
ORDER BY 
    total_revenue DESC
LIMIT 10;
