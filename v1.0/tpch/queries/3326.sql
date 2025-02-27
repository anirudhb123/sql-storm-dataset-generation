WITH nation_summary AS (
    SELECT n.n_name AS nation_name,
           SUM(s.s_acctbal) AS total_acctbal,
           COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name
),
part_supplier AS (
    SELECT p.p_partkey,
           p.p_name,
           ps.ps_suppkey,
           ps.ps_availqty,
           ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) as rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 100
),
order_details AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
           COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
)
SELECT ps.p_partkey,
       ps.p_name,
       ns.nation_name,
       ps.ps_supplycost,
       ods.order_total,
       ns.total_acctbal,
       ns.customer_count
FROM part_supplier ps
JOIN nation_summary ns ON ns.nation_name = (
    SELECT n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_suppkey = ps.ps_suppkey
)
LEFT JOIN order_details ods ON ods.o_orderkey = (
    SELECT o.o_orderkey
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_partkey = ps.p_partkey
    ORDER BY o.o_totalprice DESC
    LIMIT 1
)
WHERE ps.rn = 1
  AND (ns.total_acctbal IS NULL OR ns.customer_count > 0)
ORDER BY ps.ps_supplycost DESC, ns.total_acctbal DESC;
