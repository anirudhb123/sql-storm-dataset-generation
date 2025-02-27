WITH RECURSIVE customer_hierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 1 AS level
    FROM customer
    WHERE c_acctbal IS NOT NULL

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_nationkey = ch.c_nationkey
    WHERE c.custkey <> ch.c_custkey AND c.c_acctbal IS NOT NULL
),

ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),

aggregated_parts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),

filtered_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderstatus,
           (SELECT COUNT(DISTINCT l.l_orderkey)
            FROM lineitem l
            WHERE l.l_orderkey = o.o_orderkey AND l.l_discount > 0) AS discounted_line_count
    FROM orders o
)

SELECT coalesce(c.c_name, 'Unknown Customer') AS customer_name,
       r.s_name AS supplier_name,
       ap.total_available,
       fo.o_totalprice,
       fo.discounted_line_count,
       ROW_NUMBER() OVER (PARTITION BY coalesce(c.c_nationkey, 0) ORDER BY fo.o_totalprice DESC) AS price_rank
FROM customer_hierarchy c
FULL OUTER JOIN ranked_suppliers r ON c.c_nationkey = r.s_nationkey
LEFT JOIN aggregated_parts ap ON ap.ps_partkey = (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_availqty = (
        SELECT MAX(ps_inner.ps_availqty)
        FROM partsupp ps_inner
        WHERE ps_inner.ps_supplycost < 100
    )
    LIMIT 1
)
JOIN filtered_orders fo ON fo.o_orderkey = (
    SELECT MIN(o.o_orderkey)
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 5000
    )
WHERE c.c_acctbal IS NOT NULL
  AND (r.rank IS NULL OR r.rank <= 3)
ORDER BY c.c_nationkey DESC, fo.o_totalprice ASC
LIMIT 50;
