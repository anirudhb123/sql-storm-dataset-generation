WITH RECURSIVE nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT ns.n_nationkey, ns.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation_supplier ns
    JOIN supplier s ON ns.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal < ns.s_acctbal
), high_value_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, COUNT(l.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    GROUP BY o.o_orderkey, o.o_totalprice
), ranked_orders AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY o_orderkey ORDER BY o_totalprice DESC) AS order_rank
    FROM high_value_orders
), region_summary AS (
    SELECT r.r_regionkey, r.r_name,
           COUNT(DISTINCT ns.s_suppkey) AS supplier_count,
           SUM(ns.s_acctbal) AS total_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN nation_supplier ns ON n.n_nationkey = ns.n_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT r.r_name, rs.o_orderkey, rs.o_totalprice,
       RANK() OVER (PARTITION BY r.r_regionkey ORDER BY rs.o_totalprice DESC) AS total_rank,
       CASE WHEN r.supplier_count IS NULL THEN 'No Suppliers' ELSE CAST(r.supplier_count AS varchar) END AS suppliers_info,
       COALESCE(r.total_acctbal / NULLIF(r.supplier_count, 0), 0) AS avg_supply_balance
FROM region_summary r
JOIN ranked_orders rs ON rs.o_orderkey = r.r_regionkey
ORDER BY r.r_name, total_rank
FETCH FIRST 100 ROWS ONLY;
