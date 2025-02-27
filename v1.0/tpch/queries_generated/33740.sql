WITH RECURSIVE CustomerOrderCount AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
)
SELECT 
    c.c_name AS customer_name,
    c.order_count AS total_orders,
    s.s_name AS supplier_name,
    ss.total_available AS available_quantity,
    ss.avg_supply_cost AS average_supply_cost,
    CASE 
        WHEN ss.avg_supply_cost IS NULL THEN 'No Supply'
        ELSE 'Has Supply'
    END AS supply_status
FROM 
    CustomerOrderCount c 
LEFT OUTER JOIN 
    HighValueCustomers hc ON c.c_custkey = hc.c_custkey
LEFT JOIN 
    SupplierStats ss ON ss.total_available > 100
JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
WHERE 
    (hc.c_custkey IS NOT NULL OR c.order_count > 5)
    AND ss.avg_supply_cost IS NOT NULL
ORDER BY 
    c.total_orders DESC, ss.avg_supply_cost ASC;
