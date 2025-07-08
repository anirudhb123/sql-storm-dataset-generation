
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS total_parts_supplied
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
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_supply_value,
        total_parts_supplied,
        ROW_NUMBER() OVER (ORDER BY total_supply_value DESC) AS rank
    FROM 
        SupplierStats s
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        total_order_value,
        total_orders,
        RANK() OVER (ORDER BY total_order_value DESC) AS order_rank
    FROM 
        CustomerOrders c
)
SELECT 
    rs.s_name AS Supplier_Name,
    rs.total_supply_value AS Total_Supply_Value,
    tc.c_name AS Customer_Name,
    tc.total_order_value AS Total_Order_Value
FROM 
    RankedSuppliers rs
FULL OUTER JOIN 
    TopCustomers tc ON rs.rank = 1 AND tc.order_rank = 1
WHERE 
    (rs.total_supply_value IS NOT NULL OR tc.total_order_value IS NOT NULL)
ORDER BY 
    rs.total_supply_value DESC, 
    tc.total_order_value DESC;
