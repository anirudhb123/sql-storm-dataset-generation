WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey
),
part_supplier_summary AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
region_nation AS (
    SELECT r.r_regionkey, n.n_nationkey, r.r_name, n.n_name
    FROM region r
    INNER JOIN nation n ON r.r_regionkey = n.n_regionkey
)
SELECT
    p.p_partkey,
    p.p_name,
    (CASE 
        WHEN (ps.total_availqty IS NULL) THEN 'No Supply'
        WHEN (ps.total_availqty < 10) THEN 'Low Supply'
        ELSE 'Sufficient Supply'
    END) AS supply_status,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COALESCE(cos.total_orders, 0) AS orders_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank,
    CONCAT('Part: ', p.p_name, ', Status: ', (CASE 
        WHEN (ps.total_availqty IS NULL) THEN 'No Supply'
        WHEN (ps.total_availqty < 10) THEN 'Low Supply'
        ELSE 'Sufficient Supply'
    END)) AS status_report
FROM part p
LEFT JOIN part_supplier_summary ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
FULL OUTER JOIN customer_orders cos ON s.s_nationkey = cos.c_custkey
JOIN region_nation rn ON s.s_nationkey = rn.n_nationkey
WHERE rn.r_name LIKE 'A%' AND (p.p_retailprice BETWEEN 50.00 AND 150.00 OR p.p_comment IS NOT NULL)
ORDER BY price_rank, supply_status DESC
LIMIT 100;
