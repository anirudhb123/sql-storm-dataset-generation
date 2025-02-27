SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MIN(l.l_shipdate) AS earliest_ship_date,
    MAX(l.l_shipdate) AS latest_ship_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_list
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    customer c ON l.l_orderkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
AND 
    s.s_acctbal > 1000
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;