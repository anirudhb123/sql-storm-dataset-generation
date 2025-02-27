WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM orders o
    WHERE o.o_orderstatus <> 'F'
),
supplier_average_cost AS (
    SELECT ps.ps_suppkey,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_suppkey
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
lineitem_stats AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
           COUNT(*) AS total_items
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT c.c_name,
       cs.order_count,
       cs.total_spent,
       COALESCE(l.total_price_after_discount, 0) AS order_value,
       COALESCE(l.total_items, 0) AS item_count,
       s.s_name AS supplier_name,
       sac.avg_supply_cost
FROM customer_summary cs
JOIN customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN order_hierarchy oh ON c.c_custkey = oh.o_custkey AND oh.order_rank = 1
LEFT JOIN lineitem_stats l ON oh.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON ps.ps_partkey IN (
    SELECT p.p_partkey
    FROM part p
    WHERE p.p_retailprice > 50
)
LEFT JOIN supplier_average_cost sac ON ps.ps_suppkey = sac.ps_suppkey
LEFT JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
WHERE cs.total_spent IS NOT NULL 
  AND sac.avg_supply_cost > 20
ORDER BY cs.total_spent DESC, c.c_name;
