WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
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
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        order_count,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerOrders c
)
SELECT 
    tc.c_name AS top_customer,
    tc.total_spent AS amount_spent,
    sp.s_name AS supplier_name,
    sp.total_value AS supplier_total_value
FROM 
    TopCustomers tc
LEFT JOIN 
    SupplierParts sp ON tc.rank <= 5
WHERE 
    (tc.total_spent IS NOT NULL AND sp.total_value IS NOT NULL)
    OR (tc.total_spent IS NULL AND sp.total_value IS NULL)
ORDER BY 
    tc.total_spent DESC, sp.total_value DESC;
