WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 5 
    AND s.s_acctbal IS NOT NULL
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F' AND o.o_totalprice > 1000 -- only finalized orders over 1000
),
lineitem_stats AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS total_items,
           MAX(l.l_shipdate) AS latest_shipdate
    FROM lineitem l
    GROUP BY l.l_orderkey
),
nation_stats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 0
)
SELECT DISTINCT 
    c.c_name AS customer_name,
    n.n_name AS nation_name,
    MAX(l.total_revenue) AS max_order_revenue,
    COUNT(DISTINCT so.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT CONCAT(ps.s_name, '($', ps.s_acctbal, ')'), '; ') AS suppliers_info,
    CASE 
        WHEN SUM(l.total_revenue) IS NULL THEN 'No revenue generated'
        ELSE 'Revenue generated'
    END AS revenue_status
FROM customer_orders so
JOIN lineitem_stats l ON so.o_orderkey = l.l_orderkey
JOIN nation n ON so.c_custkey = n.n_nationkey
LEFT JOIN supplier_hierarchy sh ON l.l_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_suppkey = sh.s_suppkey)
LEFT JOIN nation_stats ns ON ns.n_nationkey = n.n_nationkey
WHERE l.latest_shipdate < CURRENT_DATE
GROUP BY c.c_custkey, n.n_nationkey
HAVING MAX(l.total_revenue) > 500
ORDER BY max_order_revenue DESC
LIMIT 10;

