WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE sh.level < 5
),
avg_price AS (
    SELECT p.p_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
nations AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    c.c_name AS customer_name,
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_in_nation,
    COALESCE(SUM(l.l_tax), 0) AS total_tax,
    COALESCE(SUM(l.l_discount), 0) AS total_discount,
    CASE 
        WHEN COUNT(DISTINCT l.l_partkey) > 3 THEN 'Diverse Supplier'
        ELSE 'Focused Supplier'
    END AS supplier_diversity
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN avg_price ap ON l.l_partkey = ap.p_partkey
JOIN nations n ON c.c_nationkey = n.n_nationkey
LEFT JOIN supplier_hierarchy sh ON c.c_nationkey = sh.s_nationkey
WHERE o.o_orderstatus = 'F'
AND l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY c.c_name, o.o_orderkey, n.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(revenue) FROM (
    SELECT SUM(l_extendedprice * (1 - l_discount)) AS revenue
    FROM lineitem
    GROUP BY l_orderkey) subquery)
ORDER BY revenue DESC
LIMIT 10;
