WITH RECURSIVE nation_sales AS (
    SELECT n.n_nationkey, n.n_name, SUM(si.l_extendedprice * (1 - si.l_discount)) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    JOIN orders o ON li.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY n.n_nationkey, n.n_name

    UNION ALL

    SELECT n.n_nationkey, n.n_name, ns.total_sales * 1.1 AS total_sales
    FROM nation_sales ns
    JOIN nation n ON ns.n_nationkey = n.n_nationkey
    WHERE ns.total_sales > 10000
),
average_sales AS (
    SELECT n_name, AVG(total_sales) AS avg_sales
    FROM nation_sales
    GROUP BY n_name
),
top_regions AS (
    SELECT r.r_name, SUM(ns.total_sales) AS region_sales
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN nation_sales ns ON n.n_nationkey = ns.n_nationkey
    GROUP BY r.r_name
    HAVING COUNT(ns.n_nationkey) > 0
)
SELECT tr.r_name, COALESCE(ars.avg_sales, 0) AS average_sales, tr.region_sales
FROM top_regions tr
LEFT JOIN average_sales ars ON tr.r_name = ars.n_name
ORDER BY tr.region_sales DESC, average_sales DESC
LIMIT 10;
