WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey <> sh.s_suppkey AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderStats AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           COUNT(DISTINCT o.o_custkey) AS unique_customers,
           CASE 
               WHEN o.o_orderstatus = 'F' THEN 'Finalized'
               WHEN o.o_orderstatus = 'P' THEN 'Pending'
               ELSE 'Other'
           END AS order_status
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
RankedOrders AS (
    SELECT o.*, 
           RANK() OVER (ORDER BY o.total_revenue DESC) AS revenue_rank,
           DENSE_RANK() OVER (PARTITION BY o.order_status ORDER BY o.unique_customers DESC) AS customer_rank
    FROM OrderStats o
)
SELECT p.p_name, 
       rh.s_name, 
       ps.total_avail_qty, 
       ps.avg_supply_cost, 
       ro.total_revenue, 
       ro.revenue_rank
FROM part p 
LEFT JOIN PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy rh ON rh.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
LEFT JOIN RankedOrders ro ON ro.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_orderstatus = 'F')
WHERE ps.total_avail_qty IS NOT NULL AND ro.revenue_rank <= 5
ORDER BY ro.revenue_rank, p.p_name;
