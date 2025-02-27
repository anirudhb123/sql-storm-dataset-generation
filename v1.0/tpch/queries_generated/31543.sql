WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_name LIKE 'A%'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
ordered_stats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY o.o_orderkey
),
supplier_part_counts AS (
    SELECT ps.ps_suppkey, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
)
SELECT r.r_name, s.s_name, MAX(p.p_retailprice) AS max_retail_price, 
       COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty,
       COUNT(DISTINCT c.c_custkey) AS unique_customers,
       (SELECT AVG(total_sales) FROM ordered_stats WHERE sales_rank <= 10) AS avg_top_sales
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
WHERE p.p_size IS NOT NULL AND p.p_retailprice > 
      (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL)
GROUP BY r.r_name, s.s_name
ORDER BY r.r_name, max_retail_price DESC;
