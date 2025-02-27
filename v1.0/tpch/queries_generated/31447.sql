WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 3
),
region_summary AS (
    SELECT r.r_regionkey, r.r_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_mktsegment = 'Retail'
    GROUP BY c.c_custkey, c.c_name
)
SELECT rs.r_name, 
       SUM(COALESCE(cs.total_spent, 0)) AS total_customer_spending,
       rg.nation_count,
       sh.level
FROM region_summary rg
FULL OUTER JOIN customer_orders cs ON rg.r_regionkey = cs.c_custkey
JOIN supplier_hierarchy sh ON sh.s_nationkey = rg.nation_count
GROUP BY rs.r_name, rg.nation_count, sh.level
HAVING SUM(COALESCE(cs.total_spent, 0)) > 10000
ORDER BY total_customer_spending DESC, rg.nation_count ASC;
