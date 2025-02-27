WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, 0 AS level
    FROM region
    WHERE r_name = 'ASIA'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, rh.level + 1
    FROM nation n
    JOIN RegionHierarchy rh ON n.n_regionkey = rh.r_regionkey
),
SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost, COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
LineItemAggregate AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2023-12-31'
    GROUP BY l.l_orderkey
)
SELECT rh.r_name AS region_name, 
       COUNT(DISTINCT ss.s_suppkey) AS total_suppliers,
       SUM(cs.total_orders) AS total_orders,
       SUM(cs.total_revenue) AS total_revenue,
       SUM(l.total_line_item_value) AS total_line_item_value,
       AVG(ss.total_supply_cost) AS avg_supply_cost,
       AVG(cs.total_orders) AS avg_orders_per_customer,
       AVG(cs.total_revenue) AS avg_revenue_per_customer
FROM RegionHierarchy rh
LEFT JOIN SupplierStats ss ON ss.s_suppkey IN (SELECT DISTINCT s.s_suppkey FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE n.n_regionkey = rh.r_regionkey)
LEFT JOIN CustomerOrderStats cs ON cs.c_custkey IN (SELECT DISTINCT c.c_custkey FROM customer c JOIN nation n ON c.c_nationkey = n.n_nationkey WHERE n.n_regionkey = rh.r_regionkey)
LEFT JOIN LineItemAggregate l ON l.l_orderkey IN (SELECT DISTINCT o.o_orderkey FROM orders o JOIN customer c ON o.o_custkey = c.c_custkey WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = rh.r_regionkey))
GROUP BY rh.r_name
ORDER BY total_orders DESC, total_revenue DESC;
