WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerOrders c
    WHERE 
        total_spent IS NOT NULL
)
SELECT 
    cu.c_name AS Customer_Name,
    cu.total_spent AS Total_Spent,
    COALESCE(sp.s_name, 'No Supplier') AS Supplier_Name,
    COALESCE(sp.total_supply_value, 0) AS Total_Supply_Value
FROM 
    TopCustomers cu
LEFT JOIN 
    SupplierParts sp ON cu.c_custkey = sp.p_partkey
WHERE 
    cu.rank <= 10
ORDER BY 
    cu.total_spent DESC;
