SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_customers
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer AS c ON c.c_nationkey = s.s_nationkey
JOIN 
    orders AS o ON c.c_custkey = o.o_custkey
JOIN 
    nation AS n ON c.c_nationkey = n.n_nationkey
JOIN 
    region AS r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 100
GROUP BY 
    p.p_partkey, p.p_name, s.s_name
HAVING 
    SUM(ps.ps_availqty) > 500
ORDER BY 
    avg_supply_cost DESC;
