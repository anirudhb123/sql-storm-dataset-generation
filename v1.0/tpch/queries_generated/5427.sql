WITH nation_supplier AS (
    SELECT n.n_name, s.s_suppkey, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
),
part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps
),
lineitem_summary AS (
    SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity, SUM(l.l_extendedprice) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2022-01-01' AND l.l_shipdate < DATE '2023-01-01'
    GROUP BY l.l_partkey
),
supplier_metrics AS (
    SELECT ns.n_name, ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(s.s_acctbal) AS avg_acctbal, 
           COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM nation_supplier ns
    JOIN part_supplier ps ON ns.s_suppkey = ps.ps_suppkey
    GROUP BY ns.n_name, ps.ps_partkey
)
SELECT sm.n_name, sm.ps_partkey, sm.total_avail_qty, sm.avg_acctbal, ls.total_quantity, ls.total_revenue
FROM supplier_metrics sm
JOIN lineitem_summary ls ON sm.ps_partkey = ls.l_partkey
WHERE sm.total_avail_qty > 100 AND sm.avg_acctbal > 5000
ORDER BY ls.total_revenue DESC, sm.n_name ASC
LIMIT 100;
