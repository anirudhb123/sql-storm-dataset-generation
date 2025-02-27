WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate <= '2022-12-31'
),
OrderLineItems AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY o.o_orderkey
),
FinalReport AS (
    SELECT cp.s_name, cp.p_name, co.c_name, co.o_orderkey, co.o_orderdate, ol.total_revenue, cp.ps_availqty, cp.ps_supplycost
    FROM SupplierParts cp
    JOIN CustomerOrders co ON cp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = cp.s_suppkey)
    JOIN OrderLineItems ol ON co.o_orderkey = ol.o_orderkey
)
SELECT s_name, p_name, c_name, o_orderkey, o_orderdate, total_revenue, ps_availqty, ps_supplycost
FROM FinalReport
ORDER BY total_revenue DESC, o_orderdate DESC
LIMIT 100;
