WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS avg_order_value
    FROM orders o
    INNER JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_acctbal > 0
    GROUP BY o.o_custkey
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, SUM(si.total_cost) AS total_supplier_cost
    FROM nation n
    JOIN SupplierInfo si ON n.n_nationkey = si.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    ORDER BY total_supplier_cost DESC
    LIMIT 5
)
SELECT tn.n_name, co.order_count, co.avg_order_value, tn.total_supplier_cost
FROM CustomerOrders co
JOIN TopNations tn ON co.o_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey IN (tn.n_nationkey)
)
ORDER BY tn.total_supplier_cost DESC, co.avg_order_value DESC;
