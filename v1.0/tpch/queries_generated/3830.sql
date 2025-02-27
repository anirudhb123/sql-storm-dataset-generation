WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_supply_value
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_supply_value > (
            SELECT AVG(total_supply_value) FROM SupplierStats
        )
),
TopCustomers AS (
    SELECT 
        cos.c_custkey,
        cos.c_name,
        cos.total_spent,
        RANK() OVER (ORDER BY cos.total_spent DESC) AS spending_rank
    FROM 
        CustomerOrderStats cos
    WHERE 
        cos.order_count > 5
)
SELECT 
    hvs.s_suppkey,
    hvs.s_name,
    tc.c_custkey,
    tc.c_name,
    tc.total_spent AS customer_total_spent,
    hvs.total_supply_value AS supplier_total_supply_value,
    CASE 
        WHEN tc.customer_total_spent > hvs.total_supply_value THEN 'Above Supplier Value'
        ELSE 'Below Supplier Value'
    END AS comparison_status
FROM 
    HighValueSuppliers hvs
FULL OUTER JOIN 
    TopCustomers tc ON hvs.s_suppkey IS NOT NULL AND tc.c_custkey IS NOT NULL
WHERE 
    (hvs.s_suppkey IS NOT NULL OR tc.c_custkey IS NOT NULL)
ORDER BY 
    hvs.total_supply_value DESC, tc.total_spent DESC;
