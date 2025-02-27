WITH RECURSIVE SupplierProfit AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * l.l_quantity) AS total_profit
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * l.l_quantity) > 10000
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.total_profit * 1.1
    FROM SupplierProfit sp
    WHERE sp.total_profit < 50000
), 
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS high_value_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
TopSuppliers AS (
    SELECT s.*, ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY sp.total_profit DESC) AS rn
    FROM supplier s
    JOIN SupplierProfit sp ON s.s_suppkey = sp.s_suppkey
)
SELECT t.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count, COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM nation t
LEFT JOIN customer c ON t.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN TopSuppliers s ON c.c_nationkey = s.s_nationkey
WHERE s.rn <= 3
GROUP BY t.n_name
ORDER BY order_count DESC, supplier_count DESC
LIMIT 10;
