WITH SupplierParts AS (
    SELECT s.s_name AS supplier_name, 
           p.p_name AS part_name, 
           ps.ps_availqty AS available_quantity, 
           ps.ps_supplycost AS supply_cost, 
           (SELECT SUM(ps1.ps_availqty)
            FROM partsupp ps1
            WHERE ps1.ps_partkey = ps.ps_partkey) AS total_available_quantity
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_name AS customer_name,
           o.o_orderkey AS order_key,
           o.o_orderdate AS order_date,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_name, o.o_orderkey, o.o_orderdate
),
AggregatedData AS (
    SELECT sp.supplier_name,
           sp.part_name,
           sp.available_quantity,
           sp.supply_cost,
           co.customer_name,
           co.order_key,
           co.order_date,
           co.total_price,
           CASE 
               WHEN co.total_price IS NULL THEN 'No Orders'
               ELSE 'Placed Order'
           END AS order_status
    FROM SupplierParts sp
    LEFT JOIN CustomerOrders co ON sp.part_name LIKE '%' || SUBSTRING(co.customer_name FROM 1 FOR 3) || '%'
)
SELECT supplier_name,
       part_name,
       available_quantity,
       supply_cost,
       customer_name,
       order_key,
       order_date,
       total_price,
       order_status
FROM AggregatedData
WHERE order_status = 'Placed Order'
ORDER BY total_price DESC
LIMIT 50;
