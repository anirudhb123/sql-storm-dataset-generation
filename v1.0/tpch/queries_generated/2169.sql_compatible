
WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.total_orders,
        cust.total_spent,
        RANK() OVER (ORDER BY cust.total_spent DESC) AS spend_rank
    FROM 
        CustomerOrderSummary cust
    WHERE 
        cust.total_spent > 1000
),
TopSuppliers AS (
    SELECT 
        supp.s_suppkey,
        supp.s_name,
        supp.total_supply_cost,
        supp.part_count,
        RANK() OVER (ORDER BY supp.total_supply_cost DESC) AS supply_rank
    FROM 
        SupplierPartSummary supp
    WHERE 
        supp.part_count > 5
)
SELECT 
    COALESCE(c.c_name, '') AS customer_name,
    COALESCE(c.total_orders, 0) AS total_orders,
    COALESCE(c.total_spent, 0) AS total_spent,
    COALESCE(s.s_name, '') AS supplier_name,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(s.part_count, 0) AS part_count
FROM 
    HighValueCustomers c
FULL OUTER JOIN 
    TopSuppliers s ON c.c_custkey IS NULL OR s.s_suppkey IS NULL
WHERE 
    (c.spend_rank <= 10 OR s.supply_rank <= 10)
ORDER BY 
    COALESCE(c.total_spent, 0) DESC, 
    COALESCE(s.total_supply_cost, 0) DESC;
