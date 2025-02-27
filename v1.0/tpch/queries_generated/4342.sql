WITH supplier_totals AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), 
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 
lineitem_aggregated AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS item_count
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' 
      AND l.l_shipdate < '2024-01-01'
    GROUP BY l.l_orderkey
)

SELECT 
    s.s_name, 
    st.total_supply_cost,
    co.c_name, 
    co.order_count, 
    co.total_spent, 
    la.total_revenue, 
    la.item_count
FROM supplier_totals st
JOIN supplier s ON st.s_suppkey = s.s_suppkey
RIGHT JOIN customer_orders co ON co.total_spent > 1000
FULL OUTER JOIN lineitem_aggregated la ON la.total_revenue IS NOT NULL
WHERE st.total_supply_cost IS NOT NULL OR co.order_count > 0 OR la.item_count > 0
ORDER BY st.total_supply_cost DESC NULLS LAST, co.total_spent DESC, la.total_revenue DESC;
