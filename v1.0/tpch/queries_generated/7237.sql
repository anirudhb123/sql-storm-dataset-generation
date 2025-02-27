WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
), 
TopCustomers AS (
    SELECT r.r_name, COUNT(DISTINCT o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM RankedOrders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE o.order_rank <= 10
    GROUP BY r.r_name
), 
SupplierPerformance AS (
    SELECT ps.ps_suppkey, s.s_name, SUM(l.l_quantity * (l.l_extendedprice - l.l_extendedprice * l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31' AND s.s_acctbal > 1000
    GROUP BY ps.ps_suppkey, s.s_name
)
SELECT t.r_name, t.total_orders, t.total_spent, s.s_name, s.total_revenue
FROM TopCustomers t
JOIN SupplierPerformance s ON t.total_spent > 10000
ORDER BY t.total_orders DESC, t.total_spent DESC, s.total_revenue DESC
LIMIT 50;
