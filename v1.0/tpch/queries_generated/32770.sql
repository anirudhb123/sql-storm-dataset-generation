WITH RECURSIVE nation_sales (n_nationkey, total_sales) AS (
    SELECT n.n_nationkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY n.n_nationkey
    UNION ALL
    SELECT ns.n_nationkey,
           ns.total_sales + (0.1 * ns.total_sales) AS total_sales
    FROM nation_sales ns
    WHERE ns.total_sales IS NOT NULL
),
customer_order_count AS (
    SELECT c.c_custkey,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
sales_ranking AS (
    SELECT ns.n_nationkey,
           ns.total_sales,
           ROW_NUMBER() OVER (ORDER BY ns.total_sales DESC) AS sales_rank
    FROM nation_sales ns
)
SELECT r.r_name,
       COALESCE(s.total_sales, 0) AS total_sales,
       COALESCE(c.order_count, 0) AS order_count
FROM region r
LEFT JOIN (
    SELECT n.n_regionkey,
           SUM(ns.total_sales) AS total_sales
    FROM nation n
    JOIN nation_sales ns ON n.n_nationkey = ns.n_nationkey
    GROUP BY n.n_regionkey
) s ON r.r_regionkey = s.n_regionkey
LEFT JOIN customer_order_count c ON c.order_count > 5
WHERE r.r_name IS NOT NULL
ORDER BY r.r_name;
