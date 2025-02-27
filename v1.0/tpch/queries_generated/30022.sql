WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
region_stats AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey
),
combined AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
           SUM(ps.ps_availqty) AS total_available,
           RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost) DESC) AS brand_rank
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
)
SELECT r.r_name, cs.total_sales, cs.supplier_count, cs.total_available
FROM region_stats r
JOIN (
    SELECT cs.r_regionkey, cs.total_sales, cs.supplier_count, cs.total_available
    FROM combined cs
    JOIN supplier_hierarchy sh ON cs.supplier_count = sh.s_suppkey
) as cs ON r.r_regionkey = cs.r_regionkey
WHERE r.nation_count > 2
ORDER BY r.r_name ASC, cs.total_sales DESC;
