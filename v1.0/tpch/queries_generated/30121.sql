WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.level < 5 AND s.s_acctbal > 1000
), 
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
    WHERE p.p_size > 10 
    GROUP BY p.p_partkey, p.p_name
),
CustomerAnalysis AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS orders_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    ph.p_name AS part_name,
    ph.avg_supply_cost,
    ph.total_revenue,
    ph.order_count,
    ca.c_name AS customer_name,
    ca.total_spent,
    (SELECT COUNT(*) 
     FROM lineitem l2 
     WHERE l2.l_quantity > (
         SELECT AVG(l3.l_quantity) 
         FROM lineitem l3
         WHERE l3.l_orderkey = l2.l_orderkey
     )
    ) AS high_quantity_orders,
    CASE 
        WHEN ca.total_spent IS NULL THEN 'No Orders'
        ELSE 'Orders Placed'
    END AS order_status
FROM PartStats ph
FULL OUTER JOIN CustomerAnalysis ca ON ph.order_count > 0
WHERE ph.avg_supply_cost IS NOT NULL 
AND coalesce(ca.orders_count, 0) > 5
ORDER BY ph.total_revenue DESC, ca.total_spent DESC;
