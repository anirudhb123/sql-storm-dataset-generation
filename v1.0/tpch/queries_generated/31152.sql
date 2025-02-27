WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey, 1 AS level
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey, oh.level + 1
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
supplier_stats AS (
    SELECT s.s_suppkey, COUNT(ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost) AS total_supplycost,
           AVG(s.s_acctbal) AS average_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(l.l_linenumber) AS total_items,
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l.l_orderkey
)
SELECT oh.level, oh.o_orderkey, oh.o_orderdate, oh.c_name, r.r_name, ss.part_count,
       ss.total_supplycost, ss.average_balance, ls.total_sales
FROM order_hierarchy oh
LEFT JOIN nation n ON oh.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
FULL OUTER JOIN supplier_stats ss ON ss.s_suppkey = oh.o_orderkey % 10
JOIN lineitem_summary ls ON ls.l_orderkey = oh.o_orderkey
WHERE ss.part_count IS NOT NULL OR ls.total_sales IS NULL
ORDER BY oh.level DESC, ls.total_sales DESC
LIMIT 100 OFFSET 20;
