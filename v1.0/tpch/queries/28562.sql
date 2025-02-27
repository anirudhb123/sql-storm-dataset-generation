SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_discounted_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_supply_cost DESC, nation_name ASC;