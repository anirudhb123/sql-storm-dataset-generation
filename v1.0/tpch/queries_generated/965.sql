WITH RankedSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name,
           s.s_nationkey,
           s.s_acctbal,
           DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
),
TotalLineItems AS (
    SELECT l.l_suppkey,
           SUM(l.l_quantity) AS total_quantity,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_suppkey
),
TopSuppliers AS (
    SELECT rs.s_suppkey, 
           rs.s_name, 
           rs.s_nationkey,
           tl.total_quantity,
           tl.total_revenue
    FROM RankedSuppliers rs
    JOIN TotalLineItems tl ON rs.s_suppkey = tl.l_suppkey
    WHERE rs.rank <= 3
),
NationRevenue AS (
    SELECT n.n_name, 
           SUM(ts.total_revenue) AS total_revenue
    FROM nation n
    LEFT JOIN TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
    GROUP BY n.n_name
)
SELECT nr.n_name,
       COALESCE(nr.total_revenue, 0) AS revenue,
       CASE 
           WHEN nr.total_revenue IS NULL THEN 'No Revenue'
           ELSE 'Has Revenue'
       END AS revenue_status
FROM NationRevenue nr
ORDER BY revenue DESC
UNION ALL
SELECT 'Total' AS n_name, 
       SUM(COALESCE(nr.total_revenue, 0)) AS total_revenue,
       'Aggregate' AS revenue_status
FROM NationRevenue nr;
