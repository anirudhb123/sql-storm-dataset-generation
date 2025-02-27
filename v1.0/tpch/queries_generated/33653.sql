WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS depth
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, sh.s_nationkey, depth + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey AND sh.s_suppkey != s.s_suppkey
    WHERE depth < 5
),
part_supplier_summary AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
order_analysis AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS line_count,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT n.n_name AS nation_name,
       pss.p_partkey,
       pss.p_name,
       pss.total_cost,
       oa.total_revenue,
       oa.line_count,
       CASE 
           WHEN oa.line_count > 5 THEN 'High Volume'
           ELSE 'Low Volume'
       END AS volume_category,
       sh.depth AS supplier_depth
FROM part_supplier_summary pss
LEFT JOIN order_analysis oa ON pss.p_partkey IN (
    SELECT DISTINCT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= '2023-01-01')
) 
LEFT JOIN nation n ON pss.supplier_count = n.n_nationkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE pss.total_cost IS NOT NULL 
AND (pss.supplier_count > 5 OR pss.total_cost > 10000)
ORDER BY nation_name, total_revenue DESC;
