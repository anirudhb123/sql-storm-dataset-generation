WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey = (SELECT MIN(n_nationkey) FROM nation)
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
suppliers_ranked AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CASE WHEN c.c_acctbal IS NULL THEN 'Unknown' ELSE 'Known' END AS account_status
    FROM customer c
    WHERE c.c_mktsegment IN ('Corporate', 'Consumer')
),
part_order_summary AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY p.p_partkey
)
SELECT nh.n_name, nh.level,
       COALESCE(sr.s_name, 'No Supplier') AS supplier_name,
       hvc.c_name, hvc.account_status, hvc.c_acctbal,
       p.p_name, p.total_revenue,
       CASE 
           WHEN total_revenue > 10000 THEN 'High Revenue'
           WHEN total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
           ELSE 'Low Revenue'
       END AS revenue_category
FROM nation_hierarchy nh
LEFT JOIN suppliers_ranked sr ON nh.n_nationkey = sr.s_suppkey
LEFT JOIN high_value_customers hvc ON nh.n_nationkey = hvc.c_nationkey
JOIN part_order_summary p ON p.p_partkey = sr.s_suppkey
WHERE nh.level < 3
ORDER BY nh.level, revenue_category DESC, hvc.c_acctbal DESC;
