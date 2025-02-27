WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
NationRegion AS (
    SELECT n.n_nationkey, r.r_regionkey, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, r.r_regionkey
    HAVING COUNT(DISTINCT c.c_custkey) > 5
)

SELECT 
    o.o_orderkey, 
    o.o_orderdate, 
    so.s_name AS supplier_name, 
    n.r_regionkey, 
    COALESCE(nc.customer_count, 0) AS customer_count,
    RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
FROM RankedOrders o
JOIN TopSuppliers so ON o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = so.s_suppkey)
JOIN NationRegion n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_orderkey)
LEFT JOIN NationRegion nc ON nc.n_nationkey = n.n_nationkey
WHERE o.revenue_rank <= 5
ORDER BY o.o_orderdate, supplier_name DESC;
