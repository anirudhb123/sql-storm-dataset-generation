WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 as level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 5
),
order_details AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
nation_region AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT sh.s_name, nr.r_name, COUNT(DISTINCT od.o_orderkey) AS order_count,
       AVG(od.total_price) AS avg_total_price,
       MIN(od.total_price) AS min_total_price,
       MAX(od.total_price) AS max_total_price
FROM supplier_hierarchy sh
LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
LEFT JOIN order_details od ON ps.ps_partkey = od.o_orderkey
LEFT JOIN nation_region nr ON sh.s_nationkey = nr.n_nationkey
WHERE nr.r_name IS NOT NULL
GROUP BY sh.s_name, nr.r_name
HAVING COUNT(DISTINCT od.o_orderkey) > 10
ORDER BY avg_total_price DESC
LIMIT 15;
