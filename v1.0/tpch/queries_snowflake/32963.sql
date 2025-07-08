
WITH RECURSIVE sales_cte AS (
    SELECT s.s_nationkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_returnflag = 'N'
    GROUP BY s.s_nationkey
    UNION ALL
    SELECT n.n_nationkey, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN orders o ON n.n_nationkey = o.o_orderkey
    GROUP BY n.n_nationkey
)
SELECT r.r_name, COALESCE(s.total_sales, 0) AS total_sales
FROM region r
LEFT JOIN (
    SELECT r.r_regionkey, SUM(total_sales) AS total_sales
    FROM sales_cte sc
    JOIN nation n ON sc.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY r.r_regionkey
) s ON r.r_regionkey = s.r_regionkey
WHERE r.r_name LIKE '%North%'
ORDER BY total_sales DESC;
