WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_totalprice, o_orderdate, o_orderstatus, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus <> 'O'
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierStats AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost) AS total_supply_cost,
           MAX(ps.ps_availqty) AS max_avail_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
TotalCosts AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT cs.c_name, cs.total_spent, cs.order_count, cs.avg_order_value,
       p.p_name, p.ps_supplycost, p.max_avail_qty,
       th.level, th.o_orderdate
FROM CustomerStats cs
JOIN PartSupplierStats p ON cs.order_count FULLOUTER JOIN p
JOIN TotalCosts th ON th.o_orderkey = cs.c_custkey
WHERE cs.total_spent > (
    SELECT AVG(total_spent) FROM CustomerStats
)
AND p.max_avail_qty > 100
ORDER BY cs.total_spent DESC, th.o_orderdate ASC
LIMIT 100;
