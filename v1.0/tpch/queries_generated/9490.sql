WITH SupplierMetrics AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),

CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
),

FinalReport AS (
    SELECT 
        c.c_name AS customer_name,
        COUNT(co.o_orderkey) AS number_of_orders,
        COALESCE(SUM(co.total_order_value), 0) AS total_spent,
        COALESCE(SUM(sm.total_supply_value), 0) AS total_supplier_values,
        r.r_name AS region_name
    FROM 
        CustomerOrders co
    LEFT JOIN 
        supplier s ON co.c_custkey = s.s_nationkey
    LEFT JOIN 
        SupplierMetrics sm ON s.s_suppkey = sm.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        c.c_name, r.r_name
    ORDER BY 
        total_spent DESC
)

SELECT 
    customer_name, 
    number_of_orders, 
    total_spent, 
    total_supplier_values, 
    region_name 
FROM 
    FinalReport
WHERE 
    number_of_orders > 5
AND 
    total_spent > 10000
ORDER BY 
    total_spent DESC;
