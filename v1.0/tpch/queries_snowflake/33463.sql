
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
part_details AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
)
SELECT ns.n_name, ns.supplier_count, ns.avg_acctbal, 
       pd.p_name, pd.p_retailprice, pd.rank,
       os.total_revenue, os.line_count
FROM nation_summary ns
FULL OUTER JOIN supplier_hierarchy sh ON ns.supplier_count > 0
JOIN part_details pd ON ns.supplier_count = pd.rank AND pd.rank <= 5
LEFT JOIN order_summary os ON pd.p_partkey IN (SELECT ps.ps_partkey
                                                FROM partsupp ps
                                                WHERE ps.ps_availqty < 100)
WHERE ns.avg_acctbal IS NOT NULL OR os.total_revenue IS NOT NULL
ORDER BY ns.n_name, pd.rank DESC, os.total_revenue DESC;
