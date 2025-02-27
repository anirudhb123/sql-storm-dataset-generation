WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers,
        DATE_TRUNC('month', o.o_orderdate) AS order_month
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, order_month
),
nation_region AS (
    SELECT n.n_nationkey,
           r.r_regionkey,
           ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY COUNT(n.n_nationkey) DESC) AS nation_rank
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_nationkey, r.r_regionkey
),
high_value_part AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty * ps.ps_supplycost) > 10000
)
SELECT 
    s.s_name AS supplier_name,
    s_h.level AS hierarchy_level,
    os.total_revenue,
    os.unique_customers,
    nr.nation_rank,
    hvp.total_supply_cost
FROM supplier s
LEFT JOIN supplier_hierarchy s_h ON s.s_suppkey = s_h.s_suppkey
JOIN order_summary os ON os.o_orderkey IN (
    SELECT o.o_orderkey
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_returnflag = 'R' AND l.l_discount > 0.1
)
JOIN nation_region nr ON s.s_nationkey = nr.n_nationkey
JOIN high_value_part hvp ON hvp.ps_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 50
)
WHERE s.s_acctbal IS NOT NULL
ORDER BY os.total_revenue DESC, s_h.level;
