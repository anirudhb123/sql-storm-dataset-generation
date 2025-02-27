WITH SupplierParts AS (
    SELECT s.s_name AS supplier_name, p.p_name AS part_name, 
           ps.ps_availqty AS available_quantity, ps.ps_supplycost AS supply_cost, 
           p.p_container AS container_type, p.p_comment AS part_comment
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_name AS customer_name, o.o_orderkey AS order_key, 
           o.o_orderstatus AS order_status, o.o_totalprice AS total_price, 
           o.o_orderdate AS order_date
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
CombinedData AS (
    SELECT sp.supplier_name, sp.part_name, sp.available_quantity, 
           sp.supply_cost, sp.container_type, sp.part_comment, 
           co.customer_name, co.order_key, co.order_status, co.total_price, 
           co.order_date
    FROM SupplierParts sp
    LEFT JOIN CustomerOrders co ON COALESCE(sp.available_quantity, 0) > 0 
)
SELECT supplier_name, part_name, available_quantity, supply_cost, 
       container_type, part_comment, customer_name, order_key, 
       order_status, total_price, order_date, 
       CONCAT('Supplier: ', supplier_name, ', Part: ', part_name, 
              ', Customer: ', customer_name, ', Order: ', order_key) AS summary_info
FROM CombinedData
WHERE available_quantity > 10
ORDER BY total_price DESC, order_date ASC
LIMIT 100;
