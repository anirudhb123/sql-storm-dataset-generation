WITH RECURSIVE RecentOrders AS (
    SELECT o_custkey, o_orderkey, o_orderdate
    FROM orders
    WHERE o_orderdate >= DATEADD(DAY, -30, CURRENT_DATE)
    
    UNION ALL
    
    SELECT o.custkey, o.orderkey, o.orderdate
    FROM orders o
    JOIN RecentOrders ro ON o.custkey = ro.o_custkey
    WHERE o.orderdate < ro.o_orderdate
)
SELECT 
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(l.l_shipdate) AS last_shipdate,
    ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS national_rank,
    COALESCE(SUM(l.l_tax), 0) AS total_tax
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
WHERE 
    o.o_orderstatus = 'O'
    AND l.l_shipdate >= '2023-01-01'
    AND (l.l_returnflag IS NULL OR l.l_returnflag <> 'R')
GROUP BY 
    c.c_name, c.c_nationkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC
LIMIT 10;
