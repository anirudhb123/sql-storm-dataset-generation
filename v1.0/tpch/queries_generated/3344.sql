WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
),
TotalSupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
ProductSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    co.num_orders,
    co.total_spent,
    po.p_name,
    ps.total_supply_cost,
    ro.o_orderdate,
    ro.o_totalprice,
    ps.total_quantity_sold,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        WHEN co.total_spent > 1000 THEN 'High Roller'
        ELSE 'Regular Customer'
    END AS customer_type
FROM CustomerOrderStats co
FULL OUTER JOIN RankedOrders ro ON co.num_orders = ro.order_rank
LEFT JOIN ProductSales ps ON co.c_custkey = ps.p_partkey
LEFT JOIN part po ON ps.p_partkey = po.p_partkey
WHERE co.total_spent IS NOT NULL OR ro.o_totalprice IS NOT NULL
ORDER BY co.total_spent DESC NULLS LAST, ro.o_orderdate DESC;
