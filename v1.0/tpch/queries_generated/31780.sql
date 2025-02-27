WITH RECURSIVE RegionSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name = 'USA'
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN RegionSuppliers rs ON s.s_nationkey <> rs.s_nationkey
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS distinct_parts_count,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT rs.nation_name, AVG(o.total_revenue) AS avg_revenue, 
       MAX(o.distinct_parts_count) AS max_parts_ordered,
       STRING_AGG(DISTINCT rs.s_name, ', ') AS supplier_names
FROM RegionSuppliers rs
LEFT JOIN OrderStats o ON rs.s_nationkey = o.o_orderkey
GROUP BY rs.nation_name
HAVING AVG(o.total_revenue) > (SELECT AVG(total_revenue) FROM OrderStats) 
   AND COUNT(DISTINCT rs.s_suppkey) > 5
ORDER BY avg_revenue DESC;
