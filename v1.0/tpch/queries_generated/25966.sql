WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
CombinedData AS (
    SELECT 
        ss.s_name AS supplier_name,
        cs.c_name AS customer_name,
        ss.total_available_quantity,
        cs.total_orders,
        cs.total_spent,
        CONCAT(ss.s_name, ' supplies ', cs.c_name) AS supply_customer_relationship
    FROM 
        SupplierStats ss
    LEFT JOIN 
        CustomerOrders cs ON ss.unique_parts_supplied > 5 AND cs.total_orders > 10
)
SELECT 
    supplier_name, 
    customer_name, 
    total_available_quantity, 
    total_orders, 
    total_spent, 
    UPPER(supply_customer_relationship) AS relationship_description
FROM 
    CombinedData
WHERE 
    total_spent > 1000
ORDER BY 
    total_available_quantity DESC, total_spent DESC;
