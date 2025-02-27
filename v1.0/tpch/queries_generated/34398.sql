WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS depth
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.depth < 5
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS monthly_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
supplier_region AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation, r.r_name AS region
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT s.supp_name, sr.region, COUNT(DISTINCT t.cust_key) AS total_customers,
       SUM(os.total_revenue) AS total_monthly_revenue
FROM supplier_hierarchy s
JOIN top_customers t ON s.s_suppkey = t.c_custkey
JOIN order_summary os ON t.c_custkey = os.o_orderkey
JOIN supplier_region sr ON s.s_nationkey = sr.nation
WHERE sr.region IS NOT NULL
GROUP BY s.s_name, sr.region
HAVING COUNT(DISTINCT t.c_custkey) >= 5
ORDER BY total_monthly_revenue DESC
LIMIT 10;
