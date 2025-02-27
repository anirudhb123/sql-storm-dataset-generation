WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT sh.s_suppkey, sh.s_name, sh.s_nationkey, sh.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY sh.s_nationkey ORDER BY sh.s_acctbal DESC) 
    FROM supplier_hierarchy sh
    WHERE sh.rank_within_nation < 5
),
part_details AS (
    SELECT p.p_partkey, p.p_name, 
           CASE 
               WHEN p.p_retailprice > (SELECT AVG(p1.p_retailprice) FROM part p1) THEN 'Expensive' 
               ELSE 'Affordable' 
           END AS price_category,
           (SELECT COUNT(*) FROM lineitem l WHERE l.l_partkey = p.p_partkey) AS sales_count
    FROM part p
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey, o.o_orderdate
),
nation_region AS (
    SELECT n.n_nationkey, n.n_name, 
           r.r_name AS region_name, 
           COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    ph.p_partkey, ph.p_name, ph.price_category, ph.sales_count,
    os.o_orderdate, os.total_revenue, os.unique_parts,
    nr.region_name, nr.customer_count,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count
FROM part_details ph
LEFT JOIN order_summary os ON ph.p_partkey = os.unique_parts
FULL OUTER JOIN nation_region nr ON nr.customer_count = 0
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = nr.n_nationkey
WHERE (ph.sales_count IS NULL OR nr.customer_count > 10)
  AND (ph.price_category = 'Expensive' OR os.total_revenue > 1000)
GROUP BY ph.p_partkey, ph.p_name, ph.price_category, ph.sales_count,
         os.o_orderdate, os.total_revenue, os.unique_parts,
         nr.region_name, nr.customer_count
HAVING SUM(COALESCE(os.total_revenue, 0)) > 5000
ORDER BY ph.p_partkey DESC, os.o_orderdate ASC NULLS LAST;
