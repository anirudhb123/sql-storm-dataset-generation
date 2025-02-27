WITH RECURSIVE total_sales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
    UNION ALL
    SELECT 
        o.o_orderkey,
        ts.total + SUM(l.l_extendedprice * (1 - l.l_discount))
    FROM 
        total_sales ts
    JOIN 
        orders o ON ts.o_orderkey = o.o_orderkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    c.c_name,
    r.r_name AS region,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(ts.total) AS grand_total,
    AVG(ts.total) AS avg_order_value,
    STRING_AGG(DISTINCT p.p_name, ', ') AS purchased_parts
FROM 
    customer c
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    total_sales ts ON o.o_orderkey = ts.o_orderkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    r.r_name IS NOT NULL
    AND (c.c_acctbal > 1000 OR c.c_nationkey IS NULL)
GROUP BY 
    c.c_name, r.r_name
HAVING 
    SUM(ts.total) IS NOT NULL
ORDER BY 
    grand_total DESC;
