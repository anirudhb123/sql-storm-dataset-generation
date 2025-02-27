WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
market_analysis AS (
    SELECT c.c_mktsegment, SUM(o.o_totalprice) AS total_revenue, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_mktsegment
),
parts_summary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
lineitem_summary AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' 
    GROUP BY l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ps.total_available, 0) AS total_available,
    COALESCE(ls.net_revenue, 0) AS net_revenue,
    sa.level AS supplier_level,
    ma.total_revenue,
    ma.order_count
FROM 
    part p
LEFT JOIN parts_summary ps ON p.p_partkey = ps.p_partkey
LEFT JOIN lineitem_summary ls ON p.p_partkey = ls.l_partkey
LEFT JOIN supplier_hierarchy sa ON sa.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey IN (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = sa.s_suppkey))
LEFT JOIN market_analysis ma ON ma.c_mktsegment = 
    (SELECT c.c_mktsegment 
     FROM customer c 
     JOIN orders o ON c.c_custkey = o.o_custkey 
     WHERE o.o_orderdate BETWEEN DATEADD(month, -12, CURRENT_DATE) AND CURRENT_DATE
     ORDER BY o.o_totalprice DESC LIMIT 1)
ORDER BY p.p_partkey;
