WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.n_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost,
        CASE 
            WHEN rs.rank <= 5 THEN 'Top Supplier'
            ELSE 'Other'
        END AS supplier_category
    FROM RankedSuppliers rs
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
SupplierStats AS (
    SELECT 
        ts.s_suppkey,
        ts.s_name,
        AVG(cs.avg_order_value) AS avg_customer_order_value,
        MAX(cs.total_orders) AS max_orders
    FROM TopSuppliers ts
    LEFT JOIN CustomerOrders cs ON ts.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem li ON ps.ps_partkey = li.l_partkey
        WHERE li.l_quantity > 0
        GROUP BY ps.ps_suppkey
    )
    GROUP BY ts.s_suppkey, ts.s_name
)
SELECT 
    ss.s_suppkey,
    ss.s_name,
    ss.avg_customer_order_value,
    ss.max_orders,
    CASE 
        WHEN ss.avg_customer_order_value IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status,
    COALESCE(NULLIF(ss.avg_customer_order_value, 0), (SELECT MAX(o.o_totalprice) FROM orders o)) AS fallback_order_value
FROM SupplierStats ss
WHERE ss.avg_customer_order_value > (
    SELECT AVG(avg_order_value) FROM CustomerOrders
    WHERE total_orders > 0
)
ORDER BY ss.s_supkey DESC
LIMIT 10;
