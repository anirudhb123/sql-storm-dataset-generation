WITH RECURSIVE ranked_suppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
expensive_parts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_retailprice,
           p.p_comment,
           ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size = p.p_size)
), 
order_summary AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT ns.r_name AS region_name,
       COALESCE(SUM(es.total_revenue), 0) AS total_revenue_by_region,
       AVG(s.s_acctbal) AS avg_supplier_balance,
       COUNT(DISTINCT p.p_partkey) AS total_expensive_parts,
       MAX(r.supp_key_summary) AS max_supplier_key_summary,
       STRING_AGG(DISTINCT p.p_comment, '|') AS distinct_part_comments
FROM region ns
LEFT JOIN ranked_suppliers r
ON ns.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = r.s_nationkey AND r.supplier_rank = 1)
FULL OUTER JOIN expensive_parts p ON TRUE
LEFT JOIN order_summary es ON es.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
WHERE ns.r_name IS NOT NULL
AND (r.s_acctbal IS NOT NULL OR (r.s_acctbal IS NULL AND r.supp_key_summary IS NOT NULL))
GROUP BY ns.r_name
HAVING COUNT(p.p_partkey) > 5
OR SUM(es.total_revenue) IS NULL
ORDER BY total_revenue_by_region DESC NULLS LAST;
