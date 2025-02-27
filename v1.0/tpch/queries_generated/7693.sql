WITH Supplier_Summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
Customer_Order_Summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
Top_Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost
    FROM 
        Supplier_Summary ss
    JOIN 
        (SELECT 
            s_suppkey 
         FROM 
            Supplier_Summary 
         ORDER BY 
            total_supply_cost DESC 
         LIMIT 10) AS top ON ss.s_suppkey = top.s_suppkey
),
Top_Customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cos.total_order_value
    FROM 
        Customer_Order_Summary cos
    JOIN 
        (SELECT 
            c_custkey 
         FROM 
            Customer_Order_Summary 
         ORDER BY 
            total_order_value DESC 
         LIMIT 10) AS top ON cos.c_custkey = top.c_custkey
)
SELECT 
    ts.s_name AS supplier_name,
    tc.c_name AS customer_name,
    ts.total_supply_cost,
    tc.total_order_value
FROM 
    Top_Suppliers ts
CROSS JOIN 
    Top_Customers tc
ORDER BY 
    ts.total_supply_cost DESC, tc.total_order_value DESC;
