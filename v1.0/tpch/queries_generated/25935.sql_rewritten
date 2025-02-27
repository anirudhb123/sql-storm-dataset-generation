SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    AVG(o.o_totalprice) AS avg_order_price,
    STRING_AGG(DISTINCT CONCAT(c.c_name, '(', c.c_acctbal, ')'), '; ') AS customer_info
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
    p.p_retailprice > 20.00 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-10-31'
GROUP BY 
    SUBSTRING(p.p_name, 1, 10)
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_supply_cost DESC;