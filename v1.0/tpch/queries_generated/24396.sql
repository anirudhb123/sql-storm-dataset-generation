WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 0 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND LENGTH(c.c_name) > 0
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 2   -- Limiting the recursion depth to 2 for performance
), NationSales AS (
    SELECT n.n_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) as rank_sales
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), AggregatedSales AS (
    SELECT n.n_name, 
           COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE NULL END), 0) AS returned_sales,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_name
), FinalReport AS (
    SELECT ns.n_name AS nation_name,
           ns.total_sales,
           ns.order_count,
           as.returned_sales,
           as.total_orders,
           (ns.total_sales / NULLIF(as.total_orders, 0)) AS avg_order_value,
           CASE WHEN ns.order_count > 10 
                THEN 'High Activity' 
                ELSE 'Low Activity' END AS activity_level
    FROM NationSales ns
    JOIN AggregatedSales as ON ns.n_name = as.n_nationkey
)
SELECT f.nation_name, f.total_sales, f.order_count, f.returned_sales, f.avg_order_value, f.activity_level
FROM FinalReport f
WHERE f.total_sales IS NOT NULL
ORDER BY f.total_sales DESC, f.order_count ASC
FETCH FIRST 10 ROWS ONLY;
