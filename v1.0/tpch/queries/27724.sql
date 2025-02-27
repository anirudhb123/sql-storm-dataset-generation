
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    CONCAT('Supplier ', s.s_name, ' provides part ', p.p_name) AS description,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    (SELECT COUNT(DISTINCT c.c_custkey) 
     FROM customer c 
     JOIN orders o ON c.c_custkey = o.o_custkey 
     JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
     WHERE l.l_partkey = p.p_partkey) AS customer_count,
    MAX(p.p_retailprice) AS max_retail_price
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_brand LIKE 'Brand#%'
GROUP BY 
    s.s_name, p.p_name, p.p_partkey
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY 
    total_available_quantity DESC, supplier_name ASC;
