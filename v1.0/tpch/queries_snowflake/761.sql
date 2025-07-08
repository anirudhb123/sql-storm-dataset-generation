
WITH SupplierRevenue AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT sr.s_suppkey, sr.s_name, sr.total_revenue
    FROM SupplierRevenue sr
    WHERE sr.revenue_rank <= 5
),
NationRevenue AS (
    SELECT n.n_nationkey, n.n_name, COALESCE(SUM(tr.total_revenue), 0) AS nation_revenue
    FROM nation n
    LEFT JOIN TopSuppliers tr ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = tr.s_suppkey LIMIT 1)
    GROUP BY n.n_nationkey, n.n_name
)
SELECT nr.n_name, nr.nation_revenue,
       COUNT(DISTINCT ts.s_suppkey) AS supplier_count,
       CASE WHEN nr.nation_revenue > (SELECT AVG(nation_revenue) FROM NationRevenue) THEN 'Above Average' ELSE 'Below Average' END AS revenue_comparison
FROM NationRevenue nr
LEFT JOIN TopSuppliers ts ON ts.s_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_nationkey = nr.n_nationkey)
GROUP BY nr.n_name, nr.nation_revenue
ORDER BY nr.nation_revenue DESC;
