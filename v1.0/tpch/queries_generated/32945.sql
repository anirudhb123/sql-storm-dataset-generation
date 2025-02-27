WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CAST(s.s_name AS varchar(255)) AS full_name, 1 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CONCAT(sh.full_name, ' -> ', s.s_name), sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
AggregatedData AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS suppliers_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
SupplierStats AS (
    SELECT sh.full_name, SUM(o.total_price) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY sh.s_nationkey ORDER BY SUM(o.total_price) DESC) AS rank
    FROM SupplierHierarchy sh
    LEFT JOIN OrderDetails o ON o.o_orderkey IN (SELECT o.o_orderkey FROM orders o INNER JOIN customer c ON o.o_custkey = c.c_custkey WHERE c.c_nationkey = sh.s_nationkey)
    GROUP BY sh.full_name, sh.s_nationkey
)
SELECT r.r_name, p.p_name, ad.total_available, ad.avg_supply_cost,
       COALESCE(ss.total_orders, 0) AS total_orders
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN AggregatedData ad ON s.s_suppkey = ad.p_partkey
LEFT JOIN SupplierStats ss ON ss.full_name = CONCAT(s.s_name, ' -> Supplier')
WHERE ad.total_available > (SELECT AVG(total_available) FROM AggregatedData)
ORDER BY r.r_name, ad.avg_supply_cost DESC;
