SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name, 
    p.p_brand, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUM(CASE 
            WHEN p.p_size BETWEEN 1 AND 10 THEN 1 
            ELSE 0 
        END) AS small_parts,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_handled,
    STRING_AGG(DISTINCT n.n_name, '; ') FILTER (WHERE c.c_mktsegment = 'BUILDING') AS building_nations
FROM 
    part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN customer c ON s.s_nationkey = c.c_nationkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_brand LIKE 'Brand%'
    AND p.p_retailprice > 10.00
    AND s.s_acctbal > 500.00
GROUP BY 
    p.p_partkey, 
    p.p_brand
ORDER BY 
    avg_supply_cost DESC, 
    supplier_count ASC;
