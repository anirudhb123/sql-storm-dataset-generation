WITH SupplierPartCost AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierPartCost s
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM 
        CustomerOrderSummary c
)
SELECT 
    t_s.s_name AS supplier_name,
    t_c.c_name AS customer_name,
    t_s.total_supply_cost,
    t_c.total_spent
FROM 
    TopSuppliers t_s
JOIN 
    TopCustomers t_c ON t_s.s_supplierkey = t_c.c_custkey
WHERE 
    t_s.supplier_rank <= 10 AND 
    t_c.customer_rank <= 10
ORDER BY 
    t_s.total_supply_cost DESC, t_c.total_spent DESC;
