WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
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
    WHERE 
        o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        s.s_name,
        ss.total_supply_value,
        RANK() OVER (ORDER BY ss.total_supply_value DESC) AS supply_rank
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_supply_value > 0
),
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS spending_rank
    FROM 
        CustomerOrders co
    WHERE 
        co.total_orders > 0
)
SELECT 
    rc.s_name AS supplier_name,
    rc.total_supply_value AS supplier_value,
    tc.c_name AS customer_name,
    tc.total_spent AS customer_amount,
    CASE 
        WHEN tc.spending_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    RankedSuppliers rc
FULL OUTER JOIN 
    TopCustomers tc ON 1=1
WHERE 
    (rc.total_supply_value IS NOT NULL OR tc.total_spent IS NOT NULL)
ORDER BY 
    rc.supply_rank, tc.spending_rank;
