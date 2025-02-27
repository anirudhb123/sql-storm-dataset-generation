WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_spent,
        COALESCE(s.total_available_quantity, 0) AS total_available_quantity
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    LEFT JOIN 
        SupplierStats s ON s.total_supply_cost > 100000
    WHERE 
        co.total_spent > 5000
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    hvc.c_name AS customer_name,
    hvc.total_spent,
    hvc.total_available_quantity
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    supplier s ON hvc.total_available_quantity > 0
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    hvc.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
ORDER BY 
    region, nation, hvc.total_spent DESC;
