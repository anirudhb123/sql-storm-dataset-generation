
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        CONCAT(s.s_name, ' - ', s.s_address) AS full_details,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    sd.s_name AS Supplier_Name,
    sd.full_details AS Supplier_Full_Details,
    sd.total_parts AS Total_Parts_Supplied,
    cd.c_name AS Customer_Name,
    cd.order_count AS Total_Orders,
    cd.total_spent AS Total_Spent,
    cd.last_order_date AS Last_Order_Date
FROM 
    SupplierDetails sd
JOIN 
    CustomerOrders cd ON sd.total_parts > 0 
WHERE 
    sd.total_supplycost > 5000
ORDER BY 
    cd.total_spent DESC, sd.total_parts DESC
LIMIT 10;
