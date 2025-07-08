
SELECT 
    p.p_brand, 
    COUNT(*) AS brand_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(CASE WHEN p.p_type LIKE '%rubber%' THEN p.p_retailprice END) AS max_rubber_ret_price,
    LISTAGG(DISTINCT s.s_name, '; ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_names,
    LISTAGG(DISTINCT CONCAT(c.c_name, ' (', o.o_orderkey, ')'), ', ') WITHIN GROUP (ORDER BY c.c_name) AS customer_orders
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
    p.p_comment LIKE '%leverage%' AND 
    s.s_comment NOT LIKE '%unwanted%'
GROUP BY 
    p.p_brand, 
    p.p_type, 
    p.p_retailprice, 
    ps.ps_supplycost, 
    o.o_orderkey, 
    c.c_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    brand_count DESC;
