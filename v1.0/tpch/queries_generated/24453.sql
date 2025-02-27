WITH RECURSIVE nation_sales AS (
    SELECT n.n_nationkey, n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY n.n_nationkey, n.n_name
    UNION ALL
    SELECT ns.n_nationkey, ns.n_name, ns.total_sales * 0.95
    FROM nation_sales ns
    WHERE ns.total_sales > 50000
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS rn,
           CASE 
               WHEN o.o_orderstatus IN ('O', 'F') THEN 'Active'
               ELSE 'Inactive'
           END AS order_status
    FROM orders o
    WHERE o.o_orderdate > '2022-01-01'
),
part_summary AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(l.l_quantity) AS total_quantity,
           AVG(l.l_extendedprice) AS avg_price,
           PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY l.l_extendedprice) AS median_price
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT n.n_name,
       COUNT(DISTINCT fo.o_orderkey) AS active_orders,
       SUM(n.total_sales) AS total_nation_sales,
       ps.p_name,
       ps.total_quantity,
       ps.avg_price,
       ps.median_price
FROM nation_sales n
FULL OUTER JOIN filtered_orders fo ON n.n_nationkey = fo.o_custkey
JOIN part_summary ps ON fo.o_orderkey = ps.p_partkey
WHERE (n.total_sales IS NOT NULL OR fo.o_orderkey IS NOT NULL)
AND (ps.avg_price BETWEEN 100 AND 1000 OR ps.median_price IS NULL)
GROUP BY n.n_name, ps.p_name, ps.total_quantity, ps.avg_price, ps.median_price
HAVING SUM(n.total_sales) > 1000
ORDER BY total_nation_sales DESC, active_orders ASC
LIMIT 10;
