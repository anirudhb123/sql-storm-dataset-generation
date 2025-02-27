WITH RECURSIVE nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
),
part_supplier_details AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, ns.s_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN nation_supplier ns ON ps.ps_suppkey = ns.s_suppkey
),
order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_quantity) AS total_quantity, COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
),
final_result AS (
    SELECT ps.p_name, os.o_orderkey, os.o_totalprice, os.total_quantity, os.unique_suppliers
    FROM part_supplier_details ps
    JOIN order_summary os ON ps.p_partkey IN (
        SELECT DISTINCT l.l_partkey
        FROM lineitem l
        WHERE l.l_extendedprice > 500
    )
)
SELECT f.p_name, f.o_orderkey, f.o_totalprice, f.total_quantity, f.unique_suppliers
FROM final_result f
WHERE f.o_totalprice > (
    SELECT AVG(o_totalprice) 
    FROM order_summary
) 
ORDER BY f.o_orderkey ASC, f.total_quantity DESC
LIMIT 100;
