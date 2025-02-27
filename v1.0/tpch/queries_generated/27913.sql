SELECT 
    p.p_name,
    s.s_name,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Price: ', FORMAT(ps.ps_supplycost, 2), ', Quantity Available: ', ps.ps_availqty) AS detailed_info,
    CASE
        WHEN ps.ps_supplycost < 50 THEN 'Economical'
        WHEN ps.ps_supplycost BETWEEN 50 AND 100 THEN 'Moderate'
        ELSE 'Expensive'
    END AS price_category,
    RANK() OVER (PARTITION BY CASE 
        WHEN ps.ps_supplycost < 50 THEN 'Economical' 
        WHEN ps.ps_supplycost BETWEEN 50 AND 100 THEN 'Moderate' 
        ELSE 'Expensive' END 
        ORDER BY ps.ps_supplycost ASC) AS supply_rank
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_comment LIKE '%fragile%'
    AND s.s_comment NOT LIKE '%defective%'
ORDER BY 
    price_category, supply_rank;
