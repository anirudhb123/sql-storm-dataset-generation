WITH RECURSIVE nation_sales AS (
    SELECT n.n_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_name
    UNION ALL
    SELECT n.n_name, SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) * 1.1
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY n.n_name
), ranked_sales AS (
    SELECT ns.n_name, ns.total_sales,
           RANK() OVER (ORDER BY ns.total_sales DESC) AS sales_rank
    FROM nation_sales ns
), customer_orders AS (
    SELECT c.c_name, c.c_nationkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name, c.c_nationkey
)
SELECT co.c_name, co.order_count, rs.n_name, rs.total_sales
FROM customer_orders co
FULL OUTER JOIN ranked_sales rs ON co.c_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = rs.n_name)
WHERE co.order_count IS NOT NULL OR rs.total_sales IS NOT NULL
ORDER BY rs.total_sales DESC NULLS LAST, co.order_count DESC NULLS LAST
LIMIT 100;
