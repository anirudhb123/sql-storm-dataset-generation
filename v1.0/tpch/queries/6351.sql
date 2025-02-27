WITH SupplierAgg AS (
    SELECT s_nationkey, SUM(s_acctbal) AS total_balance, COUNT(s_suppkey) AS supplier_count
    FROM supplier
    GROUP BY s_nationkey
),
PartAgg AS (
    SELECT ps_partkey, AVG(ps_supplycost) AS avg_supply_cost
    FROM partsupp
    GROUP BY ps_partkey
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, ra.total_balance, ra.supplier_count
    FROM nation n
    JOIN SupplierAgg ra ON n.n_nationkey = ra.s_nationkey
    ORDER BY ra.total_balance DESC
    LIMIT 5
),
OrderStats AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_revenue
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_custkey
)
SELECT tn.n_name, sa.total_balance, sa.supplier_count, os.total_orders, os.total_revenue
FROM TopNations tn
JOIN SupplierAgg sa ON tn.n_nationkey = sa.s_nationkey
LEFT JOIN OrderStats os ON os.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = tn.n_nationkey ORDER BY c.c_acctbal DESC LIMIT 1)
ORDER BY sa.total_balance DESC, os.total_revenue DESC;