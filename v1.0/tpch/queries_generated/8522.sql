WITH nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
part_supplier_summary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
final_summary AS (
    SELECT ns.n_name, ps.total_availqty, ps.total_supplycost, os.total_revenue
    FROM nation_summary ns
    JOIN part_supplier_summary ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_mfgr IN (SELECT DISTINCT s.s_name FROM supplier s WHERE s.s_nationkey = ns.n_nationkey))
    JOIN order_summary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey))
)
SELECT n.n_name, COALESCE(SUM(fs.total_availqty), 0) AS total_availqty, COALESCE(SUM(fs.total_supplycost), 0) AS total_supplycost, COALESCE(SUM(fs.total_revenue), 0) AS total_revenue
FROM nation_summary n
LEFT JOIN final_summary fs ON fs.n_name = n.n_name
GROUP BY n.n_name
ORDER BY total_revenue DESC;
