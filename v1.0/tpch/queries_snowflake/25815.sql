
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(o.o_totalprice) AS max_order_total,
    LISTAGG(DISTINCT CONCAT(c.c_name, '(', c.c_acctbal, ')'), '; ') AS customer_info,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CONCAT('Suppliers: ', LISTAGG(DISTINCT s.s_name, ', ')) AS supplier_names
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
    p.p_size BETWEEN 10 AND 30
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, p.p_partkey, p.p_comment
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 1
ORDER BY 
    total_available_quantity DESC
LIMIT 50;
