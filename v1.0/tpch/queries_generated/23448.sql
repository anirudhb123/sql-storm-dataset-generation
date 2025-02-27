WITH RECURSIVE date_series AS (
    SELECT MIN(o_orderdate) AS order_date
    FROM orders
    UNION ALL
    SELECT DATE_ADD(order_date, INTERVAL 1 DAY)
    FROM date_series
    WHERE order_date < (SELECT MAX(o_orderdate) FROM orders)
), 
aggregated_supplier_data AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty) AS total_availqty,
           AVG(ps.ps_supplycost) AS avg_supplycost,
           MAX(ps.ps_supplycost) AS max_supplycost,
           MIN(ps.ps_supplycost) AS min_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
top_nations AS (
    SELECT n.n_nationkey,
           n.n_name,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN orders o ON s.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN part p ON p.p_partkey = ps.ps_partkey
        WHERE p.p_retailprice > 100
    )
    GROUP BY n.n_nationkey, n.n_name
    HAVING order_count > 10
    ORDER BY order_count DESC
    LIMIT 5
)
SELECT r.r_name,
       COALESCE(aggregated.total_availqty, 0) AS total_availqty,
       COALESCE(aggregated.avg_supplycost, 0) AS avg_supplycost,
       CASE 
           WHEN aggregated.max_supplycost IS NULL THEN 'N/A'
           ELSE CONCAT('Max Cost: ', CAST(aggregated.max_supplycost AS CHAR))
       END AS max_cost_info,
       COUNT(DISTINCT ts.n_nationkey) AS nation_count,
       DATE_FORMAT(ds.order_date, '%Y-%m-%d') AS order_date_formatted
FROM region r
LEFT JOIN top_nations ts ON r.r_regionkey = ts.n_nationkey
LEFT JOIN aggregated_supplier_data aggregated ON aggregated.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_availqty > (
        SELECT AVG(ps_availqty) FROM partsupp
    )
)
CROSS JOIN date_series ds
WHERE r.r_comment IS NOT NULL
GROUP BY r.r_name, aggregated.total_availqty, aggregated.avg_supplycost, aggregated.max_supplycost
HAVING nation_count > 1 AND order_date_formatted IS NOT NULL
ORDER BY total_availqty DESC, order_date_formatted
LIMIT 10
OPTION SQL_BIG_SELECTS=1;
