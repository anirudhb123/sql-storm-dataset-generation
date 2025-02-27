WITH RECURSIVE nation_hierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 1 AS level
    FROM nation n
    WHERE n.n_regionkey IS NOT NULL

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_regionkey
    WHERE nh.level < 10
),
supplier_stats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
aggregated_lineitems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    r.r_name,
    n.n_name,
    ns.total_supply_cost,
    co.total_orders,
    co.total_spent,
    COALESCE(ali.total_revenue, 0) AS total_revenue,
    ROUND(KNOWN_SUPPLIERS.total_cost, 2) AS known_supplier_cost,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY co.total_spent DESC) AS ranking
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_stats ns ON n.n_nationkey = ns.s_suppkey
LEFT JOIN customer_orders co ON n.n_nationkey = co.c_custkey
LEFT JOIN aggregated_lineitems ali ON co.total_orders = ali.l_orderkey
LEFT JOIN (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
    GROUP BY ps.ps_partkey
) AS KNOWN_SUPPLIERS ON ns.total_supply_cost = KNOWN_SUPPLIERS.total_cost
WHERE (co.total_spent IS NOT NULL OR ali.total_revenue IS NOT NULL)
ORDER BY total_spent DESC, total_supply_cost ASC;
