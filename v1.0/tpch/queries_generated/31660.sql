WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty < 100 AND sh.level < 10
),
customer_ranked AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           RANK() OVER (PARTITION BY c.mktsegment ORDER BY c.c_acctbal DESC) AS market_rank
    FROM customer c
    WHERE c.c_acctbal > 0
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY o.o_orderkey
),
nation_stats AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT s.s_suppkey, s.s_name, s.s_acctbal, c.c_custkey, c.c_name, 
       ns.n_name, ns.supplier_count, ns.avg_acctbal,
       o.total_revenue
FROM supplier_hierarchy s
LEFT JOIN customer_ranked c ON s.s_acctbal > c.c_acctbal
LEFT JOIN nation_stats ns ON ns.supplier_count > 0
LEFT JOIN order_summary o ON o.total_revenue > 10000
WHERE (s.s_acctbal IS NOT NULL AND c.c_custkey IS NULL)
   OR (o.total_revenue IS NULL AND ns.avg_acctbal < 5000)
ORDER BY s.s_acctbal DESC, c.c_name ASC
LIMIT 100;
