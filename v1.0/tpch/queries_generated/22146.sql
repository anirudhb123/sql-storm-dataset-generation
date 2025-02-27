WITH RECURSIVE recursive_orders AS (
    SELECT o_orderkey, o_custkey, o_totalprice, o_orderdate, o_orderstatus
    FROM orders
    WHERE o_orderstatus = 'O' OR o_orderstatus IS NULL
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
    FROM orders o
    INNER JOIN recursive_orders r ON o.o_custkey = r.o_custkey
    WHERE o.o_orderdate > r.o_orderdate
),
ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as supplier_rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL OR s.s_name LIKE '%Corp%'
),
part_summary AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 0
),
final_analysis AS (
    SELECT o.o_orderkey, o.o_totalprice, ps.total_supply_cost,
           COALESCE(r.s_name, 'Unknown') as supplier_name,
           CASE
               WHEN ps.total_supply_cost IS NULL THEN 'No Suppliers'
               WHEN ps.supplier_count > 10 THEN 'Many Suppliers'
               ELSE 'Few Suppliers'
           END as supplier_status
    FROM recursive_orders o
    LEFT JOIN part_summary ps ON o.o_orderkey % 100 = ps.p_partkey
    LEFT JOIN ranked_suppliers r ON r.s_supplierkey = (SELECT ps_suppkey FROM partsupp ps2 WHERE ps2.ps_partkey = ps.p_partkey ORDER BY ps2.ps_supplycost DESC LIMIT 1)
),
region_summary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) as nations_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
    HAVING COUNT(DISTINCT n.n_nationkey) > 1
)
SELECT fa.o_orderkey, fa.o_totalprice, fa.supplier_name, fa.supplier_status, rs.r_name
FROM final_analysis fa
JOIN region_summary rs ON fa.o_orderkey % (SELECT COUNT(* FROM region)) = (rs.nations_count % 100)
WHERE fa.o_totalprice > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus IS NOT NULL)
ORDER BY fa.o_totalprice DESC 
LIMIT 10;
