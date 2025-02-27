WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, 
           COALESCE(SUM(ps.ps_availqty), 0) AS total_available_qty,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name,
           COALESCE(sc.total_available_qty, 0) + COALESCE(ps.ps_availqty, 0) AS total_available_qty,
           SUM(sc.total_supply_cost + ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM SupplyChain sc
    LEFT JOIN supplier s ON s.s_suppkey = sc.s_suppkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE sc.total_available_qty > 0
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
),
RegionPerformance AS (
    SELECT r.r_name, 
           SUM(o.o_totalprice) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY r.r_name
)
SELECT rc.r_name AS region_name,
       COUNT(DISTINCT co.c_custkey) AS total_customers,
       SUM(co.total_spent) AS total_spent_customers,
       AVG(co.total_orders) AS avg_orders_per_customer,
       AVG(sp.total_available_qty) AS avg_supply_qty,
       SUM(sp.total_supply_cost) AS total_supply_cost,
       COALESCE(rp.total_revenue, 0) AS region_revenue
FROM RegionPerformance rp
LEFT JOIN CustomerOrders co ON rp.total_revenue > 100000
LEFT JOIN SupplyChain sp ON sp.total_available_qty > 0
LEFT JOIN region rc ON rc.r_name = rp.r_name
GROUP BY rc.r_name
HAVING SUM(co.total_spent) > 1000 AND AVG(sp.total_supply_cost) IS NOT NULL
ORDER BY region_name DESC;
