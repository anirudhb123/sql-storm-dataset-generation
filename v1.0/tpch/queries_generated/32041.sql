WITH RECURSIVE OrderCTE AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS order_level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oc.order_level + 1
    FROM orders o
    JOIN OrderCTE oc ON o.o_orderkey = oc.o_orderkey
    WHERE oc.order_level < 5
),
SupplierSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerStats AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS item_rank
    FROM lineitem l
)
SELECT p.p_name, 
       COALESCE(SUM(CASE WHEN r.order_level IS NOT NULL THEN r.o_totalprice END), 0) AS total_revenue,
       COALESCE(SUM(s.total_supply_cost), 0) AS total_supply_cost,
       cs.total_orders, cs.avg_order_value
FROM part p
LEFT JOIN RankedLineItems rli ON p.p_partkey = rli.l_partkey
LEFT JOIN OrderCTE r ON r.o_orderkey = rli.l_orderkey
LEFT JOIN SupplierSummary s ON p.p_partkey = s.ps_partkey
LEFT JOIN CustomerStats cs ON cs.total_orders > 10
GROUP BY p.p_name, cs.total_orders, cs.avg_order_value
HAVING SUM(COALESCE(r.o_totalprice, 0)) > 1000.00
ORDER BY total_revenue DESC, p.p_name;
