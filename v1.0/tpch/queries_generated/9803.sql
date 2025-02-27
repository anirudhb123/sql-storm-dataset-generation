WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate <= '2023-12-31'
),
OrderDetails AS (
    SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           SUM(l.l_quantity) AS total_items,
           COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM CustomerOrders co
    JOIN lineitem l ON co.o_orderkey = l.l_orderkey
    GROUP BY co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, p.p_type
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100.00
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM supplier s
    JOIN SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY supplier_cost DESC
    LIMIT 10
)
SELECT o.c_custkey, o.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, 
       o.total_revenue, o.total_items, ts.s_supplier_name, ts.supplier_cost
FROM OrderDetails o
JOIN TopSuppliers ts ON o.unique_suppliers = ts.s_suppkey
WHERE o.total_revenue > 5000.00
ORDER BY o.o_orderdate DESC, ts.supplier_cost DESC;
