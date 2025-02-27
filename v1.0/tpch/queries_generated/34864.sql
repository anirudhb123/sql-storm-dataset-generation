WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_nationkey = 1
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
aggregated_sales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2021-01-01'
    GROUP BY s.s_suppkey
),
frequent_sellers AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_returnflag = 'N'
    GROUP BY s.s_suppkey
    HAVING COUNT(DISTINCT l.l_orderkey) > 5
)
SELECT 
    p.p_name,
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    ns.total_sales,
    fs.order_count,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
JOIN aggregated_sales ns ON ns.s_suppkey = l.l_suppkey
JOIN frequent_sellers fs ON fs.s_suppkey = l.l_suppkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_size IN (SELECT * FROM (VALUES (10), (20), (30)) AS sizes(size))
  AND (l.l_discount IS NULL OR l.l_discount <= 0.10)
GROUP BY p.p_name, c.c_name, ns.total_sales, fs.order_count, r.r_name
ORDER BY total_orders DESC, ns.total_sales DESC
LIMIT 50;
