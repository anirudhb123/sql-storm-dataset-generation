WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_custkey, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_custkey, h.level + 1
    FROM orders o
    JOIN OrderHierarchy h ON o.o_custkey = h.o_custkey
    WHERE h.level < 5
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN OrderHierarchy oh ON c.c_custkey = oh.o_custkey
    LEFT JOIN orders o ON oh.o_orderkey = o.o_orderkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
PartsBySupplier AS (
    SELECT p.p_partkey, p.p_name, s.s_name, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT cb.c_custkey, cb.c_name, cb.order_count, cb.total_spent,
       COALESCE(p.p_name, 'No Part Available') AS part_name,
       COALESCE(ps.ps_supplycost, 0) AS supply_cost,
       cb.order_count - COALESCE(SUM(l.l_discount), 0) AS net_order_count,
       COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS returned_orders,
       MAX(l.l_shipdate) OVER (PARTITION BY cb.c_custkey) AS last_shipped_date
FROM CustomerOrderDetails cb
LEFT JOIN lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cb.c_custkey)
LEFT JOIN PartsBySupplier p ON p.rn = 1
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
WHERE cb.total_spent > 1000 AND cb.c_acctbal IS NOT NULL
GROUP BY cb.c_custkey, cb.c_name, cb.order_count, cb.total_spent, p.p_name, ps.ps_supplycost
HAVING SUM(l.l_quantity) > 10
ORDER BY cb.total_spent DESC;
