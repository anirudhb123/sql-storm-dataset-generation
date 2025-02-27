WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL 
    
    UNION ALL 

    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s2 ON ps.ps_partkey = s2.s_suppkey
    WHERE sh.level < 3
    AND s2.s_acctbal IS NOT NULL
),

order_stats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_linenumber) AS line_count,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
           RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),

region_stats AS (
    SELECT r.r_regionkey, r.r_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(CASE WHEN c.c_custkey IS NOT NULL THEN 1 ELSE 0 END) AS customer_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY r.r_regionkey, r.r_name
)

SELECT 
    rh.s_name AS supplier_name,
    os.o_orderkey AS order_number,
    os.total_sales,
    rs.r_name AS region_name,
    rs.nation_count,
    os.line_count,
    os.return_count,
    CASE 
        WHEN os.return_count > 0 THEN 'Returns Present'
        ELSE 'No Returns'
    END AS return_status,
    ROW_NUMBER() OVER (PARTITION BY rs.r_regionkey ORDER BY os.total_sales DESC) AS region_sales_rank
FROM supplier_hierarchy rh
JOIN order_stats os ON rh.s_suppkey = os.o_orderkey
JOIN region_stats rs ON rh.s_nationkey = rs.r_regionkey
WHERE os.total_sales IS NOT NULL
AND (os.line_count > 1 OR os.return_count > 0)
AND rs.customer_count > 0
ORDER BY rs.r_regionkey, os.total_sales DESC;
