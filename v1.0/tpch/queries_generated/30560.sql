WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_supplycost > (
        SELECT AVG(ps_supplycost) FROM partsupp
    ))
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS line_items,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(distinct o.o_orderkey) AS order_count,
        SUM(od.total_price) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
NationCustomer AS (
    SELECT 
        n.n_name,
        SUM(co.order_count) AS total_orders,
        AVG(co.total_spent) AS avg_spent,
        MAX(co.total_spent) AS max_spent
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY n.n_name
)
SELECT 
    n.n_name,
    nh.level,
    nc.total_orders,
    nc.avg_spent,
    nc.max_spent,
    CASE 
        WHEN nc.max_spent IS NULL THEN 'No orders'
        WHEN nc.avg_spent > 1000 THEN 'High value'
        ELSE 'Regular customer'
    END AS customer_segment
FROM NationCustomer nc
LEFT JOIN SupplierHierarchy nh ON nc.n_nationkey = nh.s_nationkey
ORDER BY nc.total_orders DESC, nc.avg_spent DESC;
