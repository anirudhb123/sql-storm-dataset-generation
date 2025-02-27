WITH RECURSIVE ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice)
        FROM orders o2
        WHERE o2.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    )
), supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
), order_summary AS (
    SELECT lo.l_orderkey, SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM lineitem lo
    WHERE lo.l_returnflag = 'N'
    GROUP BY lo.l_orderkey
), nation_stats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n 
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    r.o_orderkey,
    c.c_name,
    COALESCE(sd.part_count, 0) AS supplier_part_count,
    ns.nation_supplier_count,
    SUM(os.total_revenue) AS total_order_revenue,
    CASE 
        WHEN COUNT(so.o_orderkey) > 0 THEN 'Has Orders'
        ELSE 'No Orders'
    END AS order_status
FROM ranked_orders r
JOIN customer c ON r.o_custkey = c.c_custkey
LEFT JOIN supplier_details sd ON sd.s_acctbal > (SELECT AVG(ss.s_acctbal) FROM supplier ss)
LEFT JOIN order_summary os ON r.o_orderkey = os.l_orderkey
LEFT JOIN nation_stats ns ON c.c_nationkey = ns.n_nationkey
LEFT JOIN orders so ON c.c_custkey = so.o_custkey AND so.o_orderstatus = 'O'
WHERE (r.rn <= 3 AND nosupplier_count >= 5)
   OR (sd.part_count IS NOT NULL AND sd.part_count > 0 AND ns.supplier_count IS NULL)
GROUP BY r.o_orderkey, c.c_name, sd.part_count, ns.nation_supplier_count
HAVING SUM(os.total_revenue) IS NOT NULL
ORDER BY total_order_revenue DESC
LIMIT 50;
