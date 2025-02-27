WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON s.s_nationkey = sh.s_nationkey AND s.s_acctbal < sh.s_acctbal
    WHERE sh.level < 5
),
top_part AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS unique_parts,
           MAX(l.l_shipdate) AS last_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2021-01-01'
    GROUP BY o.o_orderkey
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, COALESCE(os.total_revenue, 0) AS total_revenue,
           COUNT(DISTINCT os.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN order_summary os ON c.c_custkey = os.o_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT n.n_name, rg.r_name, SUM(cos.total_revenue) AS total_revenue,
       COUNT(DISTINCT cos.c_custkey) AS unique_customers,
       STRING_AGG(DISTINCT tp.p_name) AS top_products
FROM nation n
JOIN region rg ON n.n_regionkey = rg.r_regionkey
JOIN customer_order_summary cos ON cos.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
JOIN top_part tp ON tp.rank <= 5
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
GROUP BY n.n_name, rg.r_name
HAVING SUM(cos.total_revenue) > 100000
ORDER BY total_revenue DESC;
