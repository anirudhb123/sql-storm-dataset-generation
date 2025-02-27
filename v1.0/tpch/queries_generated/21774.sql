WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey = (SELECT MIN(n_nationkey) FROM nation)
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
    WHERE nh.level < 3
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
supplier_stats AS (
    SELECT s.s_suppkey, AVG(s.s_acctbal) AS avg_acctbal, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey
)
SELECT
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    CASE 
        WHEN p.p_size IS NULL THEN 'Size Unknown'
        ELSE CONCAT('Size: ', p.p_size)
    END AS size_info,
    ns.n_name AS nation_name,
    COALESCE((SELECT MAX(tr.total_revenue) FROM ranked_orders tr WHERE tr.o_orderstatus = 'F'), 0) AS highest_firm_order_revenue,
    ss.avg_acctbal,
    ss.part_count,
    p.p_retailprice * COALESCE(NULLIF(ss.avg_acctbal, 0), 1) AS adjusted_price,
    ROW_NUMBER() OVER (PARTITION BY ns.n_name ORDER BY p.p_retailprice DESC) AS price_rank,
    CASE
        WHEN ss.part_count > 20 THEN 'High Count'
        ELSE 'Low Count'
    END AS part_count_status
FROM part p
LEFT JOIN supplier_stats ss ON p.p_partkey = ss.part_count
LEFT JOIN nation_hierarchy nh ON nh.n_nationkey = (SELECT MIN(n_nationkey) FROM nation)
LEFT JOIN nation ns ON nh.n_regionkey = ns.n_nationkey
WHERE p.p_retailprice BETWEEN (SELECT AVG(ps.ps_supplycost) FROM partsupp ps) AND (SELECT AVG(ps.ps_supplycost) * 1.5 FROM partsupp ps)
ORDER BY adjusted_price DESC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM part) / 2;
