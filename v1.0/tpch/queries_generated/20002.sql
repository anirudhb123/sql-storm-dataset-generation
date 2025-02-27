WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(YEAR, -1, CURRENT_DATE)
),
Summary AS (
    SELECT n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
FilteredSummary AS (
    SELECT s.n_name, s.total_revenue, s.order_count,
           ROW_NUMBER() OVER (ORDER BY s.total_revenue DESC) AS revenue_rank
    FROM Summary s
    WHERE s.total_revenue > 0
)
SELECT q.n_name AS nation_name, 
       COALESCE(a.total_revenue, 0) AS annual_revenue,
       COALESCE(b.order_count, 0) AS order_count,
       case when (b.order_count > 0) then (a.total_revenue / b.order_count) else NULL end as avg_order_value
FROM (SELECT DISTINCT n.n_name
      FROM nation n 
      LEFT JOIN RankedOrders r ON n.n_nationkey = r.o_orderstatus
      ) q
LEFT JOIN FilteredSummary a ON q.n_name = a.n_name
LEFT JOIN Summary b ON q.n_name = b.n_name
WHERE (a.total_revenue IS NOT NULL OR b.order_count IS NOT NULL)
  AND (NOT EXISTS (SELECT 1 FROM nation n2 WHERE n2.n_name = q.n_name AND n2.n_nationkey IS NULL))
ORDER BY q.n_name ASC, 
         CASE WHEN a.total_revenue IS NULL THEN 1 ELSE 0 END, 
         a.total_revenue DESC;
