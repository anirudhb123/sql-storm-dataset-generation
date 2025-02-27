WITH RecursiveCustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS recursion_level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'

    UNION ALL

    SELECT 
        rc.c_custkey,
        rc.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        rc.recursion_level + 1
    FROM RecursiveCustomerOrders rc
    JOIN orders o ON rc.c_custkey = o.o_custkey 
    WHERE o.o_orderdate > (SELECT MAX(o_orderdate) FROM orders WHERE o_custkey = rc.c_custkey) 
)
SELECT 
    rco.c_custkey,
    rco.c_name,
    SUM(rco.o_totalprice) AS total_spent,
    COUNT(DISTINCT rco.o_orderkey) AS total_orders,
    AVG(rco.o_totalprice) OVER (PARTITION BY rco.c_custkey) AS avg_order_value,
    MIN(rco.o_orderdate) AS first_order_date,
    MAX(rco.o_orderdate) AS last_order_date,
    COALESCE(SUM(pl.ps_supplycost * l.l_quantity), 0) AS total_supply_cost
FROM RecursiveCustomerOrders rco
LEFT JOIN lineitem l ON rco.o_orderkey = l.l_orderkey
LEFT JOIN partsupp pl ON l.l_partkey = pl.ps_partkey
LEFT JOIN supplier s ON pl.ps_suppkey = s.s_suppkey
GROUP BY rco.c_custkey, rco.c_name
HAVING total_spent > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderdate BETWEEN '2022-01-01' AND '2022-12-31')
ORDER BY total_spent DESC
LIMIT 10;

