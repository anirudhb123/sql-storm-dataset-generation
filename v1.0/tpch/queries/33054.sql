WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    WHERE c.c_acctbal > 1000 AND ch.level < 5
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT s.s_name, d.total_supply_value,
           DENSE_RANK() OVER (ORDER BY d.total_supply_value DESC) AS supplier_rank
    FROM SupplierDetails d
    JOIN supplier s ON s.s_suppkey = d.s_suppkey 
    WHERE d.total_supply_value > 50000
),
CustomerOrderTotals AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY c.c_custkey
)
SELECT ch.c_name, ch.c_acctbal, 
       COALESCE(t.total_order_value, 0) AS total_order_value,
       COALESCE(ts.supplier_rank, 0) AS supplier_rank
FROM CustomerHierarchy ch
LEFT JOIN CustomerOrderTotals t ON ch.c_custkey = t.c_custkey
LEFT JOIN TopSuppliers ts ON ts.s_name = (SELECT s.s_name FROM supplier s JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size >= 20) LIMIT 1)
WHERE ch.level = 1
ORDER BY ch.c_acctbal DESC, total_order_value DESC;