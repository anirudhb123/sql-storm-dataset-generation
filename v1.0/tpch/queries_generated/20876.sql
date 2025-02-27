WITH RECURSIVE supplier_rank AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS rank_level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sr.rank_level + 1
    FROM supplier s
    JOIN supplier_rank sr ON s.s_acctbal > sr.s_acctbal
    WHERE sr.rank_level < 10
),
part_availability AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
high_price_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
order_line_stats AS (
    SELECT l.l_orderkey, 
           COUNT(*) AS line_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           SUM(l.l_tax) AS total_tax,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_receiptdate DESC) AS rnk
    FROM lineitem l
    GROUP BY l.l_orderkey
),
customer_summary AS (
    SELECT c.c_nationkey, c.c_mktsegment, 
           COUNT(DISTINCT c.c_custkey) AS customer_count,
           SUM(c.c_acctbal) AS total_acctbal
    FROM customer c
    GROUP BY c.c_nationkey, c.c_mktsegment
)
SELECT 
    n.n_name,
    SUM(cs.customer_count) AS total_customers,
    COALESCE(SUM(ol.total_price), 0) AS total_order_value,
    COALESCE(SUM(hp.p_retailprice), 0) AS high_price_parts_value,
    COALESCE(SUM(pa.total_available), 0) AS total_parts_available,
    STRING_AGG(DISTINCT sr.s_name) AS suppliers,
    COUNT(DISTINCT sr.rank_level) AS num_ranks
FROM nation n
LEFT JOIN customer_summary cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN order_line_stats ol ON ol.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
LEFT JOIN high_price_parts hp ON hp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < (SELECT AVG(ps.ps_supplycost) FROM partsupp))
LEFT JOIN part_availability pa ON pa.ps_partkey IN (SELECT hp.p_partkey FROM high_price_parts hp)
LEFT JOIN supplier_rank sr ON sr.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size IS NOT NULL AND p.p_size < 100))
WHERE n.n_regionkey IS NOT NULL
GROUP BY n.n_name
HAVING COALESCE(SUM(cs.total_acctbal), 0) > 50000
ORDER BY total_order_value DESC NULLS LAST;
