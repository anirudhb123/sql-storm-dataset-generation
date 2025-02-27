
SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    CONCAT('Manufacturer: ', p.p_mfgr) AS manufacturer_info,
    COUNT(DISTINCT s.s_name) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(ps.ps_availqty) AS max_avail_qty,
    SUM(CASE 
            WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS total_discounted_price,
    r.r_name AS region_name,
    n.n_name AS nation_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey LIMIT 1)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 10 AND 50
GROUP BY 
    p.p_name, p.p_mfgr, r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT s.s_name) > 2
ORDER BY 
    total_discounted_price DESC, avg_supply_cost DESC;
