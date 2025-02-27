WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, NULL::integer AS parent_suppkey
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.s_suppkey
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_acctbal < s.s_acctbal AND s.s_acctbal < (sh.s_acctbal + 5000)
), 
order_summary AS (
    SELECT o.o_orderkey, 
           o.o_totalprice, 
           c.c_mktsegment, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank_customer
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, c.c_mktsegment
), 
region_summary AS (
    SELECT n.n_regionkey, 
           r.r_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT r.r_name,
       rs.supplier_count,
       COALESCE(os.total_revenue, 0) AS total_revenue,
       AVG(s.s_acctbal) AS avg_acctbal,
       COUNT(DISTINCT sh.s_suppkey) AS supplier_hierarchy_count
FROM region_summary rs
LEFT JOIN order_summary os ON rs.supplier_count > 5
LEFT JOIN supplier_hierarchy sh ON rs.supplier_count > 3
JOIN region r ON rs.n_regionkey = r.r_regionkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name, rs.supplier_count, os.total_revenue
HAVING SUM(rs.total_supply_cost) > 1000000
ORDER BY avg_acctbal DESC, total_revenue DESC;
