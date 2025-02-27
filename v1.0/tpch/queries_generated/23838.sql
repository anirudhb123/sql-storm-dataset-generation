WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT supplier.s_suppkey, supplier.s_name, supplier.s_nationkey, sh.level + 1
    FROM supplier
    JOIN SupplierHierarchy sh ON supplier.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
    AND supplier.s_acctbal < sh.s_acctbal
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM FilteredParts p
    WHERE p.rn <= 5
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS order_count 
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > DATEADD(month, -3, GETDATE())
    GROUP BY o.o_orderkey
),
SupplierMetrics AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING COUNT(ps.ps_partkey) > 10
),
FinalResult AS (
    SELECT 
        nh.n_name AS nation,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(os.total_revenue) AS revenue,
        SUM(sm.total_supply_cost) AS supply_cost,
        SUM(lp.l_quantity) AS total_quantity,
        ARRAY_AGG(DISTINCT p.p_name) AS part_names
    FROM nation nh
    LEFT JOIN customer c ON c.c_nationkey = nh.n_nationkey
    LEFT JOIN orders o ON o.o_custkey = c.c_custkey
    LEFT JOIN OrderStats os ON os.o_orderkey = o.o_orderkey
    LEFT JOIN SupplierMetrics sm ON sm.s_suppkey = o.o_custkey
    LEFT JOIN lineitem lp ON o.o_orderkey = lp.l_orderkey
    JOIN TopParts p ON p.p_partkey = lp.l_partkey
    GROUP BY nh.n_name
)
SELECT nation, total_orders, revenue, supply_cost, total_quantity, 
       CASE 
           WHEN total_orders IS NULL THEN 'No orders'
           WHEN revenue IS NULL THEN 'No revenue'
           ELSE 'Active'
       END AS status
FROM FinalResult
WHERE supply_cost IS NOT NULL 
ORDER BY revenue DESC, total_orders DESC;

