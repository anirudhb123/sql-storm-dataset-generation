WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey, ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
TopCustomers AS (
    SELECT rn, c_nationkey, COUNT(*) AS total_orders
    FROM RankedOrders
    WHERE rn <= 5
    GROUP BY c_nationkey, rn
),
RegionStats AS (
    SELECT r.r_name, SUM(tc.total_orders) AS order_count, AVG(o.o_totalprice) AS avg_order_amount
    FROM TopCustomers tc
    JOIN nation n ON tc.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY r.r_name
)
SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, SUM(ps.ps_availqty) AS total_avail_qty, MAX(rg.order_count) AS max_orders, MIN(rg.avg_order_amount) AS min_avg_order
FROM RegionStats rg
JOIN supplier s ON s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT n2.n_regionkey FROM nation n2 WHERE n2.n_nationkey = rg.c_nationkey))
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
GROUP BY r.r_name
ORDER BY r.r_name;
