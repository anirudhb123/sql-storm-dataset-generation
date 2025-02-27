WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1 AS level
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
aggregated_line_items AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT p.p_partkey, p.p_name, COUNT(DISTINCT l.l_orderkey) AS order_count,
       COALESCE(SUM(l.l_extendedprice), 0) AS total_sales,
       COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS returns,
       RANK() OVER (ORDER BY SUM(l.l_extendedprice) DESC) AS sales_rank,
       ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY SUM(l.l_extendedprice) DESC) AS manufacturer_rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN ranked_orders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN supplier_hierarchy sh ON l.l_suppkey = sh.s_suppkey
WHERE p.p_retailprice > 50 AND l.l_shipdate >= '2023-01-01'
GROUP BY p.p_partkey, p.p_name
HAVING COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY total_sales DESC, p.p_partkey
LIMIT 100;
