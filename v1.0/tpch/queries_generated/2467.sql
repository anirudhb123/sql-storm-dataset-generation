WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_parts,
        ss.total_available,
        ss.total_value
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_value > (SELECT AVG(total_value) FROM SupplierStats)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_orders,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        CustomerOrders co
    WHERE 
        co.total_spent IS NOT NULL
)
SELECT 
    hs.s_name AS Supplier_Name,
    hs.total_parts,
    hs.total_available,
    hs.total_value,
    tc.c_name AS Customer_Name,
    tc.total_orders,
    tc.total_spent
FROM 
    HighValueSuppliers hs
LEFT OUTER JOIN 
    TopCustomers tc ON hs.total_value > tc.total_spent
WHERE 
    tc.rank <= 10 OR tc.rank IS NULL
ORDER BY 
    hs.total_value DESC, tc.total_spent DESC;
