WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_retailprice, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM SupplierParts sp
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supplycost DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
FinalReport AS (
    SELECT cu.c_name AS customer_name, COUNT(co.o_orderkey) AS total_orders, SUM(co.total_amount) AS total_spent, ts.s_name AS top_supplier
    FROM CustomerOrders co
    JOIN TopSuppliers ts ON ts.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT sp.p_partkey FROM SupplierParts sp))
    JOIN customer cu ON co.c_custkey = cu.c_custkey
    GROUP BY cu.c_name, ts.s_name
    ORDER BY total_spent DESC
)
SELECT *
FROM FinalReport
WHERE total_orders > 1
ORDER BY total_spent DESC;
