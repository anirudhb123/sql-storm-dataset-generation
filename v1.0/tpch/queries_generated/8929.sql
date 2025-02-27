WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supplycost DESC
    LIMIT 10
),
FrequentNations AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING order_count > 100
)
SELECT r.r_name, COUNT(DISTINCT ro.o_orderkey) AS total_orders, 
       SUM(ro.o_totalprice) AS total_revenue, 
       COUNT(DISTINCT fn.n_nationkey) AS frequent_nations_count, 
       SUM(ts.total_supplycost) AS top_supplier_costs
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN RankedOrders ro ON n.n_nationkey = ro.o_custkey
JOIN FrequentNations fn ON n.n_nationkey = fn.n_nationkey
JOIN TopSuppliers ts ON n.n_nationkey = ts.s_suppkey
GROUP BY r.r_name
ORDER BY total_revenue DESC;
