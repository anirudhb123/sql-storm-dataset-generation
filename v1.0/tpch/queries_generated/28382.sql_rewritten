SELECT 
    CONCAT(s.s_name, ' (', r.r_name, ')') AS supplier_location,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(p.p_retailprice) AS avg_part_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    SUM(CASE 
        WHEN l.l_returnflag = 'R' THEN 1 
        ELSE 0 
    END) AS returned_items,
    SUM(CASE 
        WHEN l.l_linestatus = 'F' THEN l.l_quantity 
        ELSE 0 
    END) AS fulfilled_quantity
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
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
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    supplier_location
ORDER BY 
    total_revenue DESC
LIMIT 10;