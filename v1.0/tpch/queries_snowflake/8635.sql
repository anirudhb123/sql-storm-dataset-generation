WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM orders AS o
    JOIN lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopCustomerRevenue AS (
    SELECT c.c_custkey, c.c_name, SUM(ro.total_revenue) AS customer_revenue
    FROM RankedOrders AS ro
    JOIN customer AS c ON c.c_custkey = (SELECT o.o_custkey FROM orders AS o WHERE o.o_orderkey = ro.o_orderkey)
    GROUP BY c.c_custkey, c.c_name
    ORDER BY customer_revenue DESC
    LIMIT 10
),
SupplierPartRevenue AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM supplier AS s
    JOIN partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem AS l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-10-01'
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY supplier_revenue DESC
    LIMIT 5
)
SELECT tr.c_custkey, tr.c_name AS customer_name, tr.customer_revenue, spr.s_suppkey, spr.s_name AS supplier_name, spr.supplier_revenue
FROM TopCustomerRevenue AS tr
JOIN SupplierPartRevenue AS spr ON tr.customer_revenue > spr.supplier_revenue
ORDER BY tr.customer_revenue DESC, spr.supplier_revenue DESC;