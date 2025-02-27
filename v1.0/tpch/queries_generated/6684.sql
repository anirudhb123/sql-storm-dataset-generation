WITH supplier_summary AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
customer_summary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
nation_supplier AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
part_distribution AS (
    SELECT p.p_type, COUNT(DISTINCT ps.ps_partkey) AS part_count, AVG(p.p_retailprice) AS avg_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_type
)
SELECT ns.n_name, ns.supplier_count, cs.total_orders, cs.total_spent, pd.part_count, pd.avg_price
FROM nation_supplier ns
LEFT JOIN customer_summary cs ON cs.total_orders > 0
LEFT JOIN part_distribution pd ON pd.part_count > 0
WHERE ns.supplier_count > 5
ORDER BY ns.n_name, cs.total_spent DESC;
