WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'F' AND oh.level < 5
),
SupplierInfo AS (
    SELECT s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_nationkey, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
)
SELECT 
    r.r_name,
    COALESCE(so.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(co.total_order_value, 0) AS total_order_value,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY COALESCE(so.total_supply_cost, 0) DESC) AS rank
FROM region r
LEFT JOIN SupplierInfo so ON r.r_regionkey = so.s_nationkey
LEFT JOIN CustomerOrders co ON r.r_regionkey = co.c_nationkey
WHERE r.r_name LIKE 'N%' AND (total_supply_cost IS NOT NULL OR total_order_value IS NOT NULL)
ORDER BY r.r_name, total_supply_cost DESC;