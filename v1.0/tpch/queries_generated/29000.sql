WITH SupplierParts AS (
    SELECT s.s_name, p.p_name, p.p_brand, p.p_type, 
           SUM(ps.ps_availqty) AS total_available_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           STRING_AGG(DISTINCT p.p_container, ', ') AS containers,
           COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_name, p.p_name, p.p_brand, p.p_type
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderstatus, l.l_partkey, 
           l.l_quantity, l.l_extendedprice,
           CONCAT(CAST(l.l_shipdate AS VARCHAR), ' - ', l.l_comment) AS shipment_info
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT sp.s_name, sp.p_name, sp.p_brand, sp.p_type, 
       sp.total_available_qty, sp.avg_supply_cost, 
       sp.containers, sp.part_count, 
       od.o_orderkey, od.o_orderstatus, 
       od.l_quantity, od.l_extendedprice, 
       od.shipment_info
FROM SupplierParts sp
JOIN OrderDetails od ON sp.p_name LIKE '%' || od.l_partkey || '%'
WHERE sp.total_available_qty > 100
ORDER BY sp.s_name, sp.part_count DESC, od.o_orderkey;
