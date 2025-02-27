WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.n_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.n_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.n_nationkey = sh.s_suppkey
),
total_revenue AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY o.o_orderkey
),
supplier_orders AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_supply_value,
        CASE 
            WHEN COUNT(DISTINCT lo.l_orderkey) > 10 THEN 'High Volume'
            WHEN COUNT(DISTINCT lo.l_orderkey) BETWEEN 5 AND 10 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS volume_category
    FROM partsupp ps
    JOIN lineitem lo ON ps.ps_partkey = lo.l_partkey AND ps.ps_suppkey = lo.l_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
average_supply_cost AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_name,
    r.r_name,
    so.total_supply_value,
    a.avg_supplycost,
    so.volume_category,
    SH.level AS supplier_level
FROM part p
LEFT JOIN supplier_orders so ON p.p_partkey = so.ps_partkey
LEFT JOIN average_supply_cost a ON p.p_partkey = a.ps_partkey
JOIN region r ON so.ps_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_nationkey = r.r_regionkey)
LEFT JOIN supplier_hierarchy SH ON so.ps_suppkey = SH.s_suppkey
WHERE so.total_supply_value IS NOT NULL
ORDER BY r.r_name, so.total_supply_value DESC;
