SELECT 
    COUNT(DISTINCT c.c_custkey) AS distinct_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_extendedprice) AS average_lineitem_price,
    SUM(CASE 
            WHEN l.l_shipmode = 'AIR' THEN 1 
            ELSE 0 
        END) AS air_shipments,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN 1 
            ELSE 0 
        END) AS returned_items,
    SUBSTRING(n.n_name, 1, 10) AS shortened_nation_name,
    STRING_AGG(DISTINCT p.p_name, ', ') AS parts_supplied
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
GROUP BY 
    shortened_nation_name
ORDER BY 
    total_revenue DESC
LIMIT 10;