
WITH RECURSIVE supplier_rank AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
),
nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, n.n_comment, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, n.n_comment
),
high_value_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, AVG(ps.ps_supplycost) as avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
),
order_analysis AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_discount * l.l_extendedprice) AS total_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice
    HAVING SUM(l.l_discount * l.l_extendedprice) > 5000
)
SELECT ns.n_name, ns.supplier_count, sr.s_name, sr.rank, hpp.p_name, hpp.p_retailprice, oa.total_discount
FROM nation_supplier ns
LEFT JOIN supplier_rank sr ON ns.n_nationkey = sr.s_nationkey AND sr.rank <= 3
FULL OUTER JOIN high_value_parts hpp ON sr.s_suppkey = hpp.p_partkey
JOIN order_analysis oa ON oa.o_orderkey = hpp.p_partkey OR hpp.p_retailprice IS NULL
WHERE ns.supplier_count > 0
ORDER BY ns.supplier_count DESC, hpp.p_retailprice ASC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM lineitem WHERE l_returnflag = 'R');
