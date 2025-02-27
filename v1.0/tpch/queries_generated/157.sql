WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
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
HighSpendingCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_orders,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS spending_rank
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_available_quantity,
        ss.average_supply_cost,
        RANK() OVER (ORDER BY ss.total_available_quantity DESC, ss.average_supply_cost ASC) AS supplier_rank
    FROM 
        SupplierStats ss
)

SELECT 
    hsc.c_custkey,
    hsc.c_name AS customer_name,
    ts.s_suppkey,
    ts.s_name AS supplier_name,
    ts.total_available_quantity,
    ts.average_supply_cost,
    CASE 
        WHEN ts.total_available_quantity IS NULL THEN 'No available supply'
        ELSE 'Available supply'
    END AS supply_status
FROM 
    HighSpendingCustomers hsc
FULL OUTER JOIN 
    TopSuppliers ts ON hsc.c_custkey % 10 = ts.s_suppkey % 10
WHERE 
    hsc.spending_rank <= 10 OR ts.supplier_rank <= 10
ORDER BY 
    hsc.c_custkey, ts.s_suppkey;
