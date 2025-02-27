WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
national_parts AS (
    SELECT n.n_name, p.p_partkey, p.p_name, p.p_retailprice, pt.p_type
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 100)

),
total_orders AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY o.o_custkey
),
ranked_customers AS (
    SELECT c.c_custkey, c.c_name, tc.total_revenue,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY tc.total_revenue DESC) AS revenue_rank
    FROM customer c
    LEFT OUTER JOIN total_orders tc ON c.c_custkey = tc.o_custkey
)
SELECT rh.supp_name, np.n_name, np.p_name, np.p_retailprice,
       COALESCE(rc.total_revenue, 0) AS total_revenue,
       CASE 
           WHEN rc.revenue_rank IS NULL THEN 'Not Ranked'
           ELSE CAST(rc.revenue_rank AS VARCHAR)
       END AS revenue_rank
FROM supplier_hierarchy sh
JOIN national_parts np ON sh.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = np.p_partkey)
JOIN nation np ON np.n_nationkey = np.n_nationkey
LEFT JOIN ranked_customers rc ON sh.s_nationkey = rc.c_nationkey
WHERE sh.level <= 3
ORDER BY np.p_retailprice DESC, total_revenue DESC;
