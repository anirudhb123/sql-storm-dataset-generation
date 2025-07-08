WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
region_supplier AS (
    SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) as supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
average_order_value AS (
    SELECT o.o_custkey, AVG(o.o_totalprice) AS avg_totalprice
    FROM orders o
    GROUP BY o.o_custkey
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, a.avg_totalprice
    FROM customer c
    LEFT JOIN average_order_value a ON c.c_custkey = a.o_custkey
)
SELECT r.r_name, rs.supplier_count, co.c_name, co.avg_totalprice, ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY co.avg_totalprice DESC) as rank
FROM region r
JOIN region_supplier rs ON r.r_name = rs.r_name
LEFT JOIN customer_order_summary co ON rs.supplier_count > 10
WHERE co.avg_totalprice IS NOT NULL
ORDER BY r.r_name, rank
LIMIT 100;
