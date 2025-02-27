
WITH RECURSIVE CustomerTree AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 0 AS level
    FROM customer c
    WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany')

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, ct.level + 1
    FROM customer c
    JOIN CustomerTree ct ON c.c_nationkey = ct.c_nationkey
    WHERE ct.level < 3
),
SupplierOrders AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= '1995-01-01' AND l.l_shipdate < '1995-12-31'
    GROUP BY s.s_suppkey, s.s_name
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '1994-01-01' AND '1994-12-31'
),
TopSuppliers AS (
    SELECT s.s_name, so.total_sales
    FROM SupplierOrders so
    JOIN supplier s ON so.s_suppkey = s.s_suppkey
    WHERE so.total_sales > 10000
)
SELECT ct.c_name, ct.level, ts.s_name, ts.total_sales, ro.o_orderkey, ro.o_totalprice
FROM CustomerTree ct
LEFT JOIN TopSuppliers ts ON ct.c_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_name = ts.s_name)
JOIN RankedOrders ro ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ct.c_custkey)
WHERE COALESCE(ts.total_sales, 0) > 5000 AND ro.order_rank <= 10
ORDER BY ct.level, ts.total_sales DESC;
