WITH SupplierAgg AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT
    c.c_name,
    COALESCE(cos.order_count, 0) AS total_orders,
    COALESCE(cos.total_spent, 0) AS total_spent,
    COALESCE(cos.avg_order_value, 0) AS avg_order_value,
    sa.total_supply_cost,
    lis.net_revenue,
    lis.unique_parts
FROM CustomerOrderStats cos
FULL OUTER JOIN SupplierAgg sa ON cos.order_count > 0 OR sa.total_supply_cost IS NOT NULL
JOIN LineItemSummary lis ON lis.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cos.c_custkey)
LEFT JOIN nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cos.c_custkey)
WHERE (c.c_custkey IS NOT NULL OR sa.total_supply_cost IS NOT NULL)
AND (sa.total_supply_cost > 10000 OR cos.total_spent < 500)
ORDER BY total_orders DESC, total_spent DESC;
