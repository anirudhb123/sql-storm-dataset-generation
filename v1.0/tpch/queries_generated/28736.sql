WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_name, p.p_brand, 
           CONCAT('Supplier: ', s.s_name, ' supplies ', p.p_name, ' (Brand: ', p.p_brand, ')') AS supply_info
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, 
           o.o_orderdate, CONCAT('Order ', o.o_orderkey, ' placed on ', TO_CHAR(o.o_orderdate, 'YYYY-MM-DD')) AS order_info
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
), OrderLineDetails AS (
    SELECT o.o_orderkey, l.l_partkey, l.l_quantity,
           CONCAT('Line Item for Order ', o.o_orderkey, ': Part Key ', l.l_partkey, 
           ' - Quantity: ', l.l_quantity) AS line_item_info
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT sp.s_supply_info, co.order_info, old.line_item_info
FROM SupplierParts sp
JOIN CustomerOrders co ON co.o_orderkey IN (
    SELECT DISTINCT o.o_orderkey 
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE l.l_partkey IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sp.s_suppkey)
)
JOIN OrderLineDetails old ON old.o_orderkey = co.o_orderkey
WHERE sp.s_supply_info IS NOT NULL
ORDER BY sp.s_supply_info, co.order_info;
