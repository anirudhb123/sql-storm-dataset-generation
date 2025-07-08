
SELECT 
    p.p_partkey,
    p.p_name,
    LISTAGG(CONCAT(s.s_name, ' - ', s.s_address), '; ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_details,
    LISTAGG(CONCAT(o.o_orderstatus, ' ', o.o_orderpriority, ' ', o.o_comment), ', ') WITHIN GROUP (ORDER BY o.o_orderstatus) AS order_summary,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount
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
WHERE 
    p.p_name LIKE '%widget%'
    AND s.s_acctbal > 500.00
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, s.s_address, o.o_orderstatus, o.o_orderpriority, o.o_comment
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
