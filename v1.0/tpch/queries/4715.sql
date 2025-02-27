WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
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
        p.p_partkey,
        COUNT(ps.ps_partkey) AS total_supply,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(CONCAT(p.p_name, '(', ps.ps_availqty, ')'), ', ') AS available_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
TopCustomers AS (
    SELECT 
        cus.c_custkey,
        cus.c_name,
        cus.total_spent,
        DENSE_RANK() OVER (ORDER BY cus.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrderSummary cus
),
TopSuppliers AS (
    SELECT 
        sup.s_suppkey,
        sup.s_name,
        sup.total_supply_cost,
        DENSE_RANK() OVER (ORDER BY sup.total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierPartSummary sup
)
SELECT 
    tc.c_name AS Top_Customer,
    ts.s_name AS Top_Supplier,
    tc.total_spent,
    ts.total_supply_cost
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    TopSuppliers ts ON tc.customer_rank = ts.supplier_rank
WHERE 
    tc.total_spent IS NOT NULL OR ts.total_supply_cost IS NOT NULL
ORDER BY 
    COALESCE(tc.total_spent, 0) DESC, 
    COALESCE(ts.total_supply_cost, 0) DESC;
