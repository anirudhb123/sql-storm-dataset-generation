WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    UNION ALL
    SELECT sh.s_suppkey, sh.s_name, sh.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice IS NOT NULL
      AND sh.level < 5
      AND sh.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 5000
    GROUP BY c.c_custkey
),
lineitem_summary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS item_count,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY l.l_orderkey
)
SELECT DISTINCT COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
                COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
                l.total_revenue,
                c.order_count,
                sh.level
FROM customer_orders c
FULL OUTER JOIN supplier_hierarchy sh ON sh.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 0 LIMIT 1)
LEFT JOIN lineitem_summary l ON l.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey ORDER BY o.o_orderkey DESC LIMIT 1)
JOIN supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps JOIN part p ON ps.ps_partkey = p.p_partkey WHERE p.p_size > 10 AND p.p_type LIKE '%steel%' ORDER BY p.p_partkey LIMIT 1)
WHERE c.order_count IS NOT NULL
  AND (sh.level IS NULL OR sh.level >= 0)
  AND l.rn = 1
ORDER BY customer_name DESC NULLS LAST, total_revenue DESC;
