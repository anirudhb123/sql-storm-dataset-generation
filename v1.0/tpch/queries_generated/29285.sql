WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_brand AS part_brand,
        CONCAT_WS(' - ', p.p_type, p.p_container) AS part_description,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        p.p_comment AS part_comment,
        SUBSTR(s.s_comment, 1, 50) AS supplier_comment_excerpt
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
OrderSummary AS (
    SELECT 
        c.c_name AS customer_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS average_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
),
PartSupplierDetails AS (
    SELECT 
        sp.supplier_name,
        sp.part_name,
        sp.part_description,
        os.customer_name,
        os.total_orders,
        os.total_spent,
        os.average_order_value
    FROM SupplierParts sp
    CROSS JOIN OrderSummary os
)
SELECT 
    supplier_name,
    part_name,
    part_description,
    customer_name,
    total_orders,
    total_spent,
    average_order_value,
    part_comment,
    supplier_comment_excerpt
FROM PartSupplierDetails
WHERE available_quantity > 10
ORDER BY total_spent DESC, supplier_name;
