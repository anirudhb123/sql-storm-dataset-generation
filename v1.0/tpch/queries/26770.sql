SELECT 
    p.p_name AS part_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    MAX(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE NULL END) AS max_fulfilled_order_price,
    MIN(CASE WHEN c.c_mktsegment = 'BUILDING' THEN c.c_acctbal ELSE NULL END) AS min_building_cust_balance
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 20 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_returned DESC, avg_price_after_discount DESC;