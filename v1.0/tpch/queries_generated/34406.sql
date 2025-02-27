WITH RECURSIVE RecentOrders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
  
    UNION ALL
  
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, r.level + 1
    FROM orders o
    JOIN RecentOrders r ON o.o_custkey = r.o_custkey
    WHERE o.o_orderdate < r.o_orderdate
      AND r.level < 5
),
CustomerSpending AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN RecentOrders r ON c.c_custkey = r.o_custkey
    LEFT JOIN orders o ON r.o_orderkey = o.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, ps.total_supplycost,
           RANK() OVER (ORDER BY ps.total_supplycost DESC) AS rank
    FROM part p
    JOIN PartSupplierInfo ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size > 10
)

SELECT c.c_name, 
       COALESCE(cs.total_spent, 0) AS total_spent,
       tp.p_name AS top_part_name,
       tp.total_supplycost,
       CASE 
           WHEN tp.rank IS NOT NULL THEN 'In Top Parts'
           ELSE 'Not in Top Parts'
       END AS part_status,
       CASE 
           WHEN tp.total_supplycost IS NULL THEN 'No Supply Cost'
           ELSE 'Has Supply Cost'
       END AS supply_cost_status
FROM CustomerSpending cs
FULL OUTER JOIN RecentOrders ro ON cs.c_custkey = ro.o_custkey
LEFT JOIN TopParts tp ON ro.o_orderkey = tp.p_partkey
WHERE cs.total_spent >= 1000
  OR tp.total_supplycost IS NOT NULL
ORDER BY cs.total_spent DESC, tp.total_supplycost;
