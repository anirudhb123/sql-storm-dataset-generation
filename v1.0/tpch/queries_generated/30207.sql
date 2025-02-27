WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
    ORDER BY total_cost DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spending
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING order_count > 3 AND total_spending > 500
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
TotalRevenuePerNation AS (
    SELECT n.n_name, COALESCE(SUM(RecentOrders.order_revenue), 0) AS total_revenue
    FROM nation n
    LEFT JOIN CustomerOrders co ON n.n_nationkey = co.c_custkey
    LEFT JOIN RecentOrders ON co.c_custkey = RecentOrders.o_custkey
    GROUP BY n.n_name
),
RankedRevenue AS (
    SELECT n.n_name, total_revenue,
           RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM TotalRevenuePerNation n
)
SELECT r.*, ts.s_name, ts.total_cost
FROM RankedRevenue r
LEFT JOIN TopSuppliers ts ON r.revenue_rank = 1
WHERE r.total_revenue IS NOT NULL
ORDER BY r.revenue_rank;
