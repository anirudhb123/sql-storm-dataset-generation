WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp)
),
DailyRevenue AS (
    SELECT o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderdate
),
RankedRevenue AS (
    SELECT o_orderdate, revenue,
           RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
    FROM DailyRevenue
)
SELECT n.n_name, 
       COALESCE(ts.total_cost, 0) AS supplier_total_cost, 
       dr.o_orderdate, 
       dr.revenue, 
       rr.revenue_rank
FROM NationHierarchy n
LEFT JOIN TopSuppliers ts ON n.n_nationkey = ts.s_suppkey
LEFT JOIN RankedRevenue rr ON rr.o_orderdate = CURRENT_DATE - INTERVAL '1 DAY'
JOIN DailyRevenue dr ON dr.o_orderdate = rr.o_orderdate
WHERE n.n_name IS NOT NULL
AND (ts.total_cost IS NOT NULL OR rr.revenue_rank < 10)
ORDER BY n.n_name, dr.o_orderdate;
