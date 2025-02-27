WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON co.o_orderkey = o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    MAX(co.o_orderdate) AS last_order_date
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN CustomerOrders co ON l.l_orderkey = co.o_orderkey
GROUP BY p.p_partkey, p.p_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 0
ORDER BY revenue_rank, total_revenue DESC
LIMIT 10;
