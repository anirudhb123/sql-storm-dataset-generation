SELECT 
    CONCAT('[', r_name, '] (', n_name, ')') AS region_nation,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    COUNT(DISTINCT p.p_partkey) AS part_count,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    MAX(s.s_acctbal) AS max_supplier_balance,
    MIN(CASE WHEN o.o_orderstatus = 'F' THEN o.o_orderdate END) AS first_completed_order_date,
    COUNT(CASE WHEN o.o_orderpriority = 'HIGH' THEN 1 END) AS high_priority_order_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_comment LIKE '%green%'
    AND r.r_comment NOT LIKE '%obsolete%'
GROUP BY 
    r_name, n_name
ORDER BY 
    total_supply_cost DESC, supplier_count DESC;
