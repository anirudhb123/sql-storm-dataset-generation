WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 as level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL

    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, co.level + 1
    FROM CustomerOrders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate > (SELECT MAX(o2.o_orderdate) FROM orders o2 WHERE o2.o_custkey = co.c_custkey AND o2.o_orderstatus = 'O') - INTERVAL '30 days'
),
AggregatedOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
    HAVING total_value > 100000
),
RecentLineItems AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY l.l_partkey
)
SELECT 
    RANK() OVER (ORDER BY ao.total_spent DESC) AS rank,
    ao.c_name,
    ao.total_spent,
    ROUND(AVG(l.revenue), 2) AS avg_revenue_per_item,
    COALESCE(gs.total_value, 0) AS high_value_supplier,
    CASE
        WHEN ao.order_count > 10 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type
FROM AggregatedOrders ao
LEFT JOIN RecentLineItems l ON ao.c_custkey = l.l_partkey
LEFT JOIN HighValueSuppliers gs ON ao.c_custkey = gs.ps_suppkey
WHERE ao.total_spent > 5000
GROUP BY ao.c_name, ao.total_spent, gs.total_value
ORDER BY rank
LIMIT 100;

