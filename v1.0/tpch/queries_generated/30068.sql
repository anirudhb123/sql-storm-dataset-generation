WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM CustomerOrders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    WHERE o.o_orderdate > (SELECT MAX(o_orderdate) FROM orders WHERE o_custkey = co.c_custkey)
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT co.c_name) AS customer_names,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.l_quantity) AS median_quantity
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
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey = l.l_orderkey
WHERE 
    r.r_name LIKE 'Europe%'
GROUP BY 
    r.r_name, n.n_name, s.s_name, p.p_name
HAVING 
    revenue > 10000
ORDER BY 
    revenue DESC, order_count DESC;
