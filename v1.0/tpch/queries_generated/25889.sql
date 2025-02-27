WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' (Avail: ', ps.ps_availqty, ', Cost: ', FORMAT(ps.ps_supplycost, 2), ')') AS supplier_part_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_key,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS items_count,
        CONCAT(c.c_name, ' has an order (Order ID: ', o.o_orderkey, ') totaling: ', FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 2), ' with ', COUNT(l.l_orderkey), ' items.') AS customer_order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name, o.o_orderkey
)
SELECT 
    rp.supplier_part_info AS supplier_details,
    co.customer_order_info AS customer_details
FROM 
    SupplierParts rp
JOIN 
    CustomerOrders co ON rp.available_quantity > 10
WHERE 
    rp.supply_cost < 50.00
ORDER BY 
    rp.supplier_name, co.customer_name;
