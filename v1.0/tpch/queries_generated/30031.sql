WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, RAND() AS random_value
    FROM SupplierStats s
    ORDER BY s.total_available_qty DESC
    LIMIT 5
)
SELECT 
    c.c_name, 
    coalesce(cs.total_orders, 0) AS total_orders, 
    coalesce(cs.total_spent, 0.00) AS total_spent,
    s.s_name AS supplier_name,
    nh.n_name AS nation_name,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY cs.total_spent DESC) AS order_rank
FROM customer c
JOIN CustomerOrders cs ON c.c_custkey = cs.c_custkey
JOIN TopSuppliers ts ON ts.s_name = (SELECT s.s_name FROM supplier s WHERE s.s_suppkey = 
        (SELECT ps.ps_suppkey 
         FROM partsupp ps 
         WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN 
            (SELECT o.o_orderkey FROM orders o where o.o_custkey = c.c_custkey))
         LIMIT 1))
    )
LEFT JOIN nation nh ON c.c_nationkey = nh.n_nationkey
ORDER BY c.c_custkey, order_rank DESC
LIMIT 100;
