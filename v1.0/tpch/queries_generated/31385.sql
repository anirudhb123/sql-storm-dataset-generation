WITH RECURSIVE RankedCustomers AS (
    SELECT c_custkey, c_name, c_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY c_nationkey ORDER BY c_acctbal DESC) AS rank
    FROM customer
    WHERE c_acctbal IS NOT NULL
),
SupplierCosts AS (
    SELECT ps.s_suppkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.s_suppkey
),
AggregatedSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY o.o_orderkey
),
FilteredOrders AS (
    SELECT o.custkey, COUNT(o.o_orderkey) AS order_count
    FROM orders o
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.custkey
)
SELECT 
    rc.c_name, 
    rc.c_acctbal, 
    COALESCE(fc.order_count, 0) AS completed_orders,
    sc.total_supply_cost, 
    a.total_revenue,
    CASE 
        WHEN rc.rank <= 5 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM RankedCustomers rc
LEFT JOIN FilteredOrders fc ON rc.c_custkey = fc.custkey
LEFT JOIN SupplierCosts sc ON rc.c_custkey = sc.s_suppkey
LEFT JOIN AggregatedSales a ON rc.c_custkey = a.o_orderkey
WHERE rc.rank <= 10
ORDER BY rc.c_acctbal DESC, completed_orders DESC;
