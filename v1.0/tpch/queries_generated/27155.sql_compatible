
WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, p.p_brand
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
LineItemDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount, l.l_tax, l.l_shipmode, l.l_comment
    FROM lineitem l
),
OrderSummary AS (
    SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice, co.o_orderpriority,
           SUM(ld.l_extendedprice * (1 - ld.l_discount)) AS total_revenue,
           COUNT(DISTINCT sp.ps_partkey) AS distinct_parts,
           STRING_AGG(DISTINCT sp.p_brand, ', ') AS brands,
           STRING_AGG(DISTINCT ld.l_shipmode, ', ') AS shipment_modes
    FROM CustomerOrders co
    JOIN LineItemDetails ld ON co.o_orderkey = ld.l_orderkey
    JOIN SupplierParts sp ON ld.l_partkey = sp.ps_partkey
    GROUP BY co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice, co.o_orderpriority
)
SELECT os.c_custkey, os.c_name, os.o_orderkey, os.o_orderdate, os.o_totalprice, os.o_orderpriority,
       os.total_revenue, os.distinct_parts, os.brands, os.shipment_modes
FROM OrderSummary os
WHERE os.total_revenue > 1000.00
ORDER BY os.total_revenue DESC, os.o_orderdate ASC;
