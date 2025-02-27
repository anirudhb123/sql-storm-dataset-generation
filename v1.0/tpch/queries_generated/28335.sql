SELECT 
    LOWER(SUBSTRING(p.p_name FROM 1 FOR 10)) AS part_name_substring,
    COUNT(DISTINCT s.s_name) AS supplier_count,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discounted_revenue,
    CONCAT('Total: ', CAST(SUM(l.l_extendedprice) AS CHAR)) AS total_extended_price,
    MAX(l.l_shipdate) AS latest_ship_date,
    GROUP_CONCAT(DISTINCT n.n_name ORDER BY n.n_name) AS nations_supplied
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
JOIN 
    customer c ON l.l_orderkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 100 
    AND l.l_shipmode IN ('AIR', 'SEA')
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    part_name_substring
HAVING 
    supplier_count > 5
ORDER BY 
    discounted_revenue DESC
LIMIT 10;
