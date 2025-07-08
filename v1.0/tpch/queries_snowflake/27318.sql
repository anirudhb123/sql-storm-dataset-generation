
SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Nation: ', n.n_name) AS detail,
    SUM(ps.ps_availqty) AS available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey LIMIT 1)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    s.s_name, p.p_name, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    average_supply_cost DESC, unique_customers ASC
LIMIT 50;
