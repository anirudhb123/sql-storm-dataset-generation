WITH ranked_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rnk
    FROM part p
),
top_part_suppliers AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, s.s_acctbal, 
           (ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
supplier_summary AS (
    SELECT ns.n_name, SUM(tt.total_supply_value) AS total_supplier_value
    FROM nation ns
    LEFT JOIN top_part_suppliers tt ON ns.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = tt.s_suppkey)
    GROUP BY ns.n_name
),
final_summary AS (
    SELECT co.c_name, co.order_count, COALESCE(ss.total_supplier_value, 0) AS total_supplier_value,
           SUM(os.total_amount) AS total_order_value
    FROM customer_orders co
    LEFT JOIN supplier_summary ss ON co.c_name LIKE '%' || ss.n_name || '%'
    LEFT JOIN order_summary os ON co.order_count > 0
    GROUP BY co.c_name, co.order_count, ss.total_supplier_value
)
SELECT f.c_name, f.order_count, f.total_supplier_value, f.total_order_value,
       CASE WHEN f.total_order_value > 100000 THEN 'High Value' ELSE 'Low Value' END AS order_value_category
FROM final_summary f
WHERE f.total_supplier_value IS NOT NULL
ORDER BY f.total_order_value DESC, f.c_name;
