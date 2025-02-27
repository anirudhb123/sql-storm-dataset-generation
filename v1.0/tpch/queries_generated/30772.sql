WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
),
RecentOrders AS (
    SELECT oh.o_orderkey, oh.o_custkey, oh.o_orderdate, oh.o_totalprice
    FROM OrderHierarchy oh
    WHERE oh.order_rank <= 5
),
SupplierPartStats AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
TotalLineItems AS (
    SELECT l.l_orderkey, COUNT(*) AS total_items,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CustomerStats AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS number_of_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT c.c_custkey, c.c_name, cs.total_spent, cs.number_of_orders, 
       COALESCE(tr.total_revenue, 0) AS total_revenue,
       sp.total_availqty AS supplier_avail_qty, sp.avg_supplycost
FROM customer c
LEFT JOIN CustomerStats cs ON c.c_custkey = cs.c_custkey
LEFT JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
LEFT JOIN TotalLineItems tr ON ro.o_orderkey = tr.l_orderkey
LEFT JOIN SupplierPartStats sp ON EXISTS (
    SELECT 1 
    FROM partsupp ps 
    WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'BrandX')
    AND ps.ps_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = c.c_nationkey)
)
WHERE cs.total_spent > 1000 OR (cs.number_of_orders > 3 AND cs.total_spent IS NULL)
ORDER BY c.c_custkey DESC;
