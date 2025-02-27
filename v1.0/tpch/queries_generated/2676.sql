WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
OrderDetails AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS line_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    COALESCE(co.order_count, 0) AS order_count,
    COALESCE(od.line_count, 0) AS line_count,
    COALESCE(od.total_price, 0) AS total_price,
    ts.total_cost AS supplier_cost
FROM CustomerOrders co
FULL OUTER JOIN OrderDetails od ON co.order_count = od.line_count
FULL OUTER JOIN TopSuppliers ts ON ts.s_suppkey = (SELECT ps.ps_suppkey 
                                                      FROM partsupp ps 
                                                      JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
                                                      WHERE l.l_orderkey = od.o_orderkey 
                                                      LIMIT 1)
WHERE co.c_custkey IS NOT NULL OR od.o_orderkey IS NOT NULL OR ts.s_suppkey IS NOT NULL
ORDER BY co.c_custkey, od.o_orderkey DESC NULLS LAST;
