WITH RECURSIVE customer_hierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, 0 AS hierarchy_level
    FROM customer
    WHERE c_acctbal > 10000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.hierarchy_level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_custkey = ch.c_custkey
    WHERE c.c_acctbal > 20000
), nation_supplier AS (
    SELECT n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
), part_order_summary AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '2021-01-01' AND '2023-12-31'
    GROUP BY p.p_partkey
), ranked_parts AS (
    SELECT p.p_partkey, p.p_name, pos.total_revenue,
           RANK() OVER (ORDER BY pos.total_revenue DESC) AS revenue_rank
    FROM part_order_summary pos
    JOIN part p ON pos.p_partkey = p.p_partkey
)
SELECT rh.c_name, ns.n_name, rp.p_name, 
       rp.total_revenue, ns.supplier_count
FROM customer_hierarchy rh
JOIN nation_supplier ns ON rh.c_acctbal > 15000
LEFT JOIN ranked_parts rp ON rh.c_custkey = rp.p_partkey
WHERE ns.supplier_count > 5
  AND (rp.total_revenue IS NOT NULL OR rh.c_acctbal < 50000)
ORDER BY rp.total_revenue DESC NULLS LAST;
