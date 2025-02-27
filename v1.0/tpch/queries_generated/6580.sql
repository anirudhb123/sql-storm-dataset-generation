WITH SupplierParts AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rn
    FROM partsupp
    WHERE ps_availqty > 0
),
TopSuppliers AS (
    SELECT sp.ps_partkey, sp.ps_suppkey, sp.ps_supplycost
    FROM SupplierParts sp
    WHERE sp.rn <= 3
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
PurchaseInfo AS (
    SELECT co.o_orderkey, co.o_custkey, co.total_revenue, c.c_mktsegment, s.s_name
    FROM CustomerOrders co
    JOIN customer c ON co.o_custkey = c.c_custkey
    JOIN TopSuppliers ts ON ts.ps_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = ts.ps_suppkey LIMIT 1)
    JOIN supplier s ON ts.ps_suppkey = s.s_suppkey
)
SELECT pi.o_orderkey, pi.o_custkey, pi.total_revenue, pi.c_mktsegment, pi.s_name
FROM PurchaseInfo pi
WHERE pi.total_revenue > (SELECT AVG(total_revenue) FROM CustomerOrders) 
ORDER BY pi.total_revenue DESC
LIMIT 10;
