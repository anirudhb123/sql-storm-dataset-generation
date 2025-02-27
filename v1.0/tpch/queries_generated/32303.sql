WITH RECURSIVE nation_sales AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
    UNION ALL
    SELECT n.n_nationkey, n.n_name, SUM(o.o_totalprice * 0.9) -- Assume a discount for recursive aggregation
    FROM nation n
    JOIN nation_sales ns ON n.n_nationkey = ns.n_nationkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate > '2023-01-01' -- Filter for recent sales
    GROUP BY n.n_nationkey, n.n_name
),
ranked_sales AS (
    SELECT ns.n_name, ns.total_sales,
           RANK() OVER (ORDER BY ns.total_sales DESC) AS sales_rank
    FROM nation_sales ns
),
notable_customers AS (
    SELECT c.c_name, SUM(o.o_totalprice) AS customer_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
    HAVING SUM(o.o_totalprice) > 10000 -- Significant contributions
)
SELECT r.n_name, r.total_sales, nc.c_name, nc.customer_sales
FROM ranked_sales r
FULL OUTER JOIN notable_customers nc ON r.sales_rank = 1
WHERE r.total_sales IS NOT NULL OR nc.customer_sales IS NOT NULL
ORDER BY COALESCE(r.total_sales, 0) DESC, COALESCE(nc.customer_sales, 0) DESC;
