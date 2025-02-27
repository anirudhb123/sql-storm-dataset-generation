SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    s.s_name AS supplier_name,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(p.p_retailprice) AS avg_retail_price,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN 'Returned' ELSE 'Not Returned' END, ', ') AS return_status,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_name LIKE '%Steel%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_brand, p.p_type, s.s_name
ORDER BY 
    total_available_qty DESC, avg_retail_price ASC;