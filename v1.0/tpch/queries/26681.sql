SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_avail_qty,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customers_ordered,
    CASE 
        WHEN AVG(l.l_discount) > 0.1 THEN 'High Discounts'
        WHEN AVG(l.l_discount) BETWEEN 0.05 AND 0.1 THEN 'Moderate Discounts'
        ELSE 'Low Discounts'
    END AS discount_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderstatus = 'O' 
    AND l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
GROUP BY 
    p.p_name
ORDER BY 
    total_supply_cost DESC;