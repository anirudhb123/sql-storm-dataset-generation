WITH ranked_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
),
nation_info AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
),
customer_data AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS segment_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           o.o_orderstatus, c.c_mktsegment
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus, c.c_mktsegment
),
filtered_supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           CASE WHEN s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
                THEN 'above_average' 
                ELSE 'below_average' END AS balance_status
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
)
SELECT DISTINCT c.c_name,
       np.region_name,
       COALESCE(rp.p_name, 'No Part Available') AS part_name,
       os.total_revenue,
       fs.balance_status
FROM customer_data c
FULL OUTER JOIN nation_info np ON c.c_custkey % 3 = np.n_nationkey % 3
LEFT JOIN ranked_parts rp ON c.c_custkey % 5 = rp.rn
LEFT JOIN order_summary os ON c.c_custkey = os.o_orderkey
JOIN filtered_supplier fs ON fs.s_suppkey = (SELECT ps_suppkey 
                                              FROM partsupp ps 
                                              WHERE ps.ps_partkey = rp.p_partkey 
                                              ORDER BY ps.ps_supplycost ASC LIMIT 1)
WHERE (os.total_revenue IS NOT NULL OR fs.balance_status = 'above_average')
AND EXISTS (SELECT 1 FROM supplier s WHERE s.s_comment LIKE '%important%')
ORDER BY c.c_name DESC, os.total_revenue DESC;