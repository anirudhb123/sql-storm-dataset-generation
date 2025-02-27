WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment, rh.level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey = rh.r_regionkey + 1
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT 
    rh.r_name AS region_name,
    c.c_name AS customer_name,
    COALESCE(co.total_spent, 0) AS total_spent,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
    CASE
        WHEN COALESCE(co.total_spent, 0) > COALESCE(sp.total_supply_cost, 0) THEN 'High Demand'
        WHEN COALESCE(co.total_spent, 0) < COALESCE(sp.total_supply_cost, 0) THEN 'Over Supply'
        ELSE 'Balanced'
    END AS status
FROM RegionHierarchy rh
LEFT JOIN CustomerOrders co ON rh.r_regionkey = co.c_custkey
LEFT JOIN SupplierParts sp ON rh.r_regionkey = sp.s_suppkey
WHERE COALESCE(co.total_spent, 0) > 1000
ORDER BY region_name, customer_name;
