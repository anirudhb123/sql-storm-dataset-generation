WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, 
           s_name, 
           s_nationkey, 
           s_acctbal,
           1 AS level
    FROM supplier
    WHERE s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'GERMANY')
    
    UNION ALL
    
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           s.s_acctbal,
           level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderDetails AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT od.o_orderkey,
           od.o_orderdate,
           od.total_revenue,
           RANK() OVER (ORDER BY od.total_revenue DESC) AS order_rank
    FROM OrderDetails od
),
PartStats AS (
    SELECT p.p_partkey,
           p.p_brand,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_brand
)
SELECT 
    sh.s_name AS supplier_name,
    t.o_orderkey,
    t.o_orderdate,
    t.total_revenue,
    ps.p_brand,
    ps.avg_supply_cost,
    ps.supplier_count,
    CASE 
        WHEN t.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM TopOrders t
JOIN PartStats ps ON t.o_orderkey % 10 = ps.p_partkey % 10
FULL OUTER JOIN SupplierHierarchy sh ON sh.s_suppkey = t.o_orderkey % 5
WHERE sh.s_acctbal IS NOT NULL
  AND (t.total_revenue > 5000 OR ps.supplier_count > 2)
ORDER BY sh.s_name, t.o_orderdate DESC;
