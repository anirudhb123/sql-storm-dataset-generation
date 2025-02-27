WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 5
),
top_sellers AS (
    SELECT l.l_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate >= '2023-01-01'
    GROUP BY l.l_suppkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
sales_ranks AS (
    SELECT s.s_suppkey, s.s_name, COALESCE(ts.total_sales, 0) AS total_sales,
           DENSE_RANK() OVER (ORDER BY COALESCE(ts.total_sales, 0) DESC) AS sales_rank
    FROM supplier s
    LEFT JOIN top_sellers ts ON s.s_suppkey = ts.l_suppkey
),
nation_sales AS (
    SELECT n.n_name, SUM(sr.total_sales) AS nation_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN sales_ranks sr ON s.s_suppkey = sr.s_suppkey
    GROUP BY n.n_name
)
SELECT n.n_name, ns.nation_sales,
       (SELECT COUNT(*) FROM supplier_hierarchy) AS active_suppliers,
       ROUND(AVG(s.s_acctbal), 2) AS average_acct_balance,
       STRING_AGG(DISTINCT s.s_name, ', ') AS top_suppliers
FROM nation_sales ns
JOIN nation n ON ns.n_nationkey = n.n_nationkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
WHERE ns.nation_sales > 5000
GROUP BY n.n_name, ns.nation_sales
ORDER BY ns.nation_sales DESC;
