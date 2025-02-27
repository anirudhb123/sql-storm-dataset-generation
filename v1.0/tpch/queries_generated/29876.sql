SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(o.o_totalprice) AS max_total_price,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_availqty) DESC) AS availability_rank
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
WHERE 
    p.p_comment LIKE '%fragile%'
    AND s.s_comment NOT LIKE '%discount%'
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_type
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    availability_rank, p.p_name;
