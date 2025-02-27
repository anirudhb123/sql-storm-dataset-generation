WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 10000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 3
),
PartSupplier AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
LineItemSummary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS total_items
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-01-01'
    GROUP BY l.l_orderkey
),
SupplierRegion AS (
    SELECT s.s_suppkey, r.r_name
    FROM supplier s
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
),
RevenueComparison AS (
    SELECT l.o_orderkey,
           l.total_revenue,
           CASE WHEN l.total_revenue > (SELECT AVG(total_revenue) FROM LineItemSummary) 
                THEN 'Above Average' 
                ELSE 'Below Average' END AS revenue_status
    FROM LineItemSummary l
)

SELECT ch.c_name AS customer_name,
       sr.r_name AS supplier_region,
       ps.total_avail_qty,
       rc.total_revenue,
       rc.revenue_status
FROM CustomerHierarchy ch
JOIN SupplierRegion sr ON sr.s_suppkey IN (SELECT ps.ps_suppkey FROM PartSupplier ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '2023-01-01')))
JOIN PartSupplier ps ON ps.ps_suppkey IN (SELECT ls.l_suppkey FROM lineitem ls WHERE ls.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O'))
JOIN RevenueComparison rc ON rc.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
ORDER BY ch.c_name, sr.r_name;
