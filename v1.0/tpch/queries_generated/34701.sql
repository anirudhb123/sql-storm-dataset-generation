WITH RECURSIVE nation_path AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS depth
    FROM nation
    WHERE n_nationkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, np.depth + 1
    FROM nation n
    JOIN nation_path np ON n.n_regionkey = np.n_nationkey
),
supplier_summary AS (
    SELECT s.s_nationkey, COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           SUM(s.s_acctbal) AS total_balance,
           AVG(s.s_acctbal) AS avg_balance
    FROM supplier s
    GROUP BY s.s_nationkey
),
part_stats AS (
    SELECT p.p_partkey, p.p_name, p.p_brand,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
),
final_results AS (
    SELECT p.p_partkey, p.p_name, ps.total_available, ps.avg_cost,
           ns.total_suppliers, ns.avg_balance, os.total_sales,
           RANK() OVER (PARTITION BY ns.n_nationkey ORDER BY os.total_sales DESC) AS sales_rank
    FROM part_stats ps
    JOIN supplier_summary ns ON ps.supplier_count = ns.total_suppliers
    LEFT JOIN order_summary os ON ns.total_suppliers = (SELECT COUNT(*) FROM supplier WHERE s_nationkey = ns.s_nationkey)
)
SELECT f.p_partkey, f.p_name, f.total_available, f.avg_cost,
       f.total_suppliers, f.avg_balance, f.total_sales, f.sales_rank,
       COALESCE(f.total_sales, 0) AS adjusted_sales,
       CASE WHEN f.sales_rank IS NULL THEN 'No Sales' ELSE 'Has Sales' END AS sales_status
FROM final_results f
LEFT JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT MIN(n_nationkey) FROM nation_path))
ORDER BY f.sales_rank, f.p_partkey;
