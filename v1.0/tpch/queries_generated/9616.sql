WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_retailprice
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, o.o_orderdate
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
Summary AS (
    SELECT sp.s_suppkey, sp.s_name, co.c_custkey, co.c_name, od.total_revenue, COUNT(od.o_orderkey) AS order_count
    FROM SupplierParts sp
    JOIN CustomerOrders co ON sp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sp.s_suppkey)
    JOIN OrderDetails od ON co.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = od.o_orderkey)
    GROUP BY sp.s_suppkey, sp.s_name, co.c_custkey, co.c_name, od.total_revenue
)
SELECT s.s_name, c.c_name, SUM(su.total_revenue) AS revenue, COUNT(DISTINCT c.c_custkey) AS customer_count
FROM Summary su
JOIN supplier s ON su.s_suppkey = s.s_suppkey
JOIN customer c ON su.c_custkey = c.c_custkey
GROUP BY s.s_name, c.c_name
ORDER BY revenue DESC
LIMIT 10;
