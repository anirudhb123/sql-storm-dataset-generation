WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        1 AS order_depth
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    UNION ALL
    SELECT 
        co.c_custkey,
        co.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        co.order_depth + 1 AS order_depth
    FROM 
        CustomerOrders co
    JOIN 
        orders o ON co.o_orderkey = o.o_orderkey
)
SELECT 
    r.r_name,
    n.n_name,
    SUM(ps.ps_supplycost * l.l_quantity * (1 - l.l_discount)) AS total_cost,
    COUNT(DISTINCT o.o_orderkey) AS num_orders,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS avg_returned_quantity,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(ps.ps_supplycost * l.l_quantity * (1 - l.l_discount)) DESC) AS rank
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
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey = o.o_orderkey
WHERE 
    r.r_name LIKE '%Asia%' 
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_cost DESC;