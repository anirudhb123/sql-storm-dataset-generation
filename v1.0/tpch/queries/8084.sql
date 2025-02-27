WITH SupplierParts AS (
    SELECT s.s_name, p.p_name, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
),
TopSuppliers AS (
    SELECT s_name, SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM SupplierParts
    GROUP BY s_name
    ORDER BY total_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
),
LineItemDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY o.o_orderkey
)
SELECT ts.s_name, co.c_name, co.o_orderkey, co.o_totalprice, ld.total_revenue
FROM TopSuppliers ts
JOIN CustomerOrders co ON ts.s_name = (SELECT s_name FROM SupplierParts WHERE ps_supplycost = (SELECT MAX(ps_supplycost) FROM SupplierParts WHERE s_name = ts.s_name) LIMIT 1)
JOIN LineItemDetails ld ON co.o_orderkey = ld.o_orderkey
ORDER BY ts.total_cost DESC, ld.total_revenue DESC;
