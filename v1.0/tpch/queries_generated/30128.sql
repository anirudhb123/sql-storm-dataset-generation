WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, 1 AS level
    FROM customer
    WHERE c_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
),
TopSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
    HAVING COUNT(DISTINCT ps.ps_partkey) > 5
),
OrderStats AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value
    FROM orders o
    GROUP BY o.o_custkey
),
FilteredCustomers AS (
    SELECT ch.c_custkey, ch.c_name, os.order_count, os.total_spent, os.avg_order_value
    FROM CustomerHierarchy ch
    JOIN OrderStats os ON ch.c_custkey = os.o_custkey
    WHERE os.total_spent > 1000
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, DENSE_RANK() OVER (ORDER BY ts.total_cost DESC) AS supplier_rank
    FROM supplier s
    JOIN TopSuppliers ts ON s.s_suppkey = ts.ps_suppkey
)
SELECT fc.c_name, fc.order_count, fc.total_spent, rs.s_name AS top_supplier, rs.supplier_rank,
       CASE WHEN fc.total_spent > AVG(fc.total_spent) OVER() THEN 'Above Average' ELSE 'Below Average' END AS spending_status
FROM FilteredCustomers fc
LEFT JOIN RankedSuppliers rs ON fc.order_count >= 5
ORDER BY fc.total_spent DESC, rs.supplier_rank ASC
LIMIT 10;
