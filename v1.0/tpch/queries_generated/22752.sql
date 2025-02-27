WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_name LIKE 'Supplier%'
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS recent_order_num
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'P')
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
AggregatedData AS (
    SELECT p.p_name, p.p_size, ps.total_avail_qty, p.p_retailprice,
           COALESCE(ps.total_avail_qty, 0) * p.p_retailprice AS computed_value
    FROM part p
    LEFT JOIN PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
),
RegionalPurchases AS (
    SELECT r.r_name, COUNT(DISTINCT co.o_orderkey) AS order_count,
           SUM(co.o_totalprice) AS total_revenue
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN customerorders co ON c.c_custkey = co.c_custkey
    WHERE co.recent_order_num = 1
    GROUP BY r.r_name
)
SELECT a.p_name, a.p_size, a.computed_value,
       COALESCE(rp.order_count, 0) AS regional_order_count,
       COALESCE(rp.total_revenue, 0) AS total_revenue,
       SH.level AS supplier_level,
       CASE 
           WHEN a.computed_value IS NULL THEN 'Unknown'
           WHEN rp.total_revenue > 10000 THEN 'High Revenue'
           ELSE 'Low Revenue' 
       END AS revenue_category
FROM AggregatedData a
LEFT JOIN RegionalPurchases rp ON rp.total_revenue > a.p_retailprice
JOIN SupplierHierarchy SH ON SH.s_suppkey = a.p_size % 10
ORDER BY a.computed_value DESC, revenue_category, SH.level;
