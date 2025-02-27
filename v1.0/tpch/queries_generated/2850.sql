WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemAnalysis AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linestatus) AS line_item_rank
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT cs.c_name AS customer_name,
       ss.s_name AS supplier_name,
       ss.total_supply_cost,
       cs.total_spent,
       la.total_line_item_value,
       CASE 
           WHEN cs.total_orders > 0 THEN ROUND(cs.total_spent / cs.total_orders, 2) 
           ELSE NULL 
       END AS avg_order_value,
       la.line_item_rank
FROM CustomerOrderSummary cs
FULL OUTER JOIN SupplierSummary ss ON cs.total_orders > 5 AND ss.part_count >= 10
JOIN LineItemAnalysis la ON la.l_orderkey = (SELECT o.o_orderkey 
                                             FROM orders o 
                                             WHERE o.o_custkey = cs.c_custkey 
                                             ORDER BY o.o_orderdate DESC 
                                             LIMIT 1)
WHERE ss.total_supply_cost IS NOT NULL OR cs.total_spent IS NOT NULL
ORDER BY cs.total_spent DESC NULLS LAST, ss.total_supply_cost DESC NULLS LAST;
