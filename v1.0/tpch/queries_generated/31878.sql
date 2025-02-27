WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.nationkey, sh.level + 1
    FROM supplier_HIERARCHY sh
    JOIN supplier s ON sh.nationkey = s.nationkey
    WHERE sh.level < 5
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
           COUNT(l.l_orderkey) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
filtered_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_supplycost,
           (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0 OR ps.ps_supplycost IS NULL
),
debug_info AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice) AS total_extended_price,
           AVG(COALESCE(l.l_discount, 0)) AS average_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT DISTINCT n.n_name, SUM(os.total_amount) AS total_order_amount, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       (SELECT COUNT(*)
        FROM supplier_hierarchy sh
        WHERE sh.level <= 3 AND sh.s_acctbal > 500)
FROM nation n
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN order_summary os ON os.o_orderkey = o.o_orderkey
LEFT JOIN filtered_parts fp ON fp.p_partkey = c.c_custkey
CROSS JOIN debug_info di
WHERE n.n_comment LIKE '%important%'
GROUP BY n.n_name
HAVING COUNT(os.total_amount) > 10
ORDER BY total_order_amount DESC
LIMIT 10;
