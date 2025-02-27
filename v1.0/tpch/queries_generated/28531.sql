SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ' - Price: $', FORMAT(ps.ps_supplycost, 2)) AS supply_info,
    CASE 
        WHEN ps.ps_availqty < 100 THEN 'Low Stock' 
        WHEN ps.ps_availqty BETWEEN 100 AND 500 THEN 'Medium Stock' 
        ELSE 'High Stock' 
    END AS stock_status,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' - ', c.c_address), '; ') AS associated_customers,
    ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rank_by_cost
FROM 
    partsupp ps
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    s.s_suppkey, s.s_name, p.p_name, ps.ps_supplycost, ps.ps_availqty
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    stock_status, s.s_name;
