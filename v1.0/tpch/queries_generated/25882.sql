WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierCustomerAnalysis AS (
    SELECT 
        rs.s_name AS supplier_name,
        hc.c_name AS customer_name,
        hc.total_spent,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    CROSS JOIN 
        HighValueCustomers hc
)
SELECT 
    supplier_name,
    customer_name,
    total_spent,
    total_cost,
    CONCAT(supplier_name, ' supplies to ', customer_name, ' with total spending of $', ROUND(total_spent, 2), ' and supplier cost of $', ROUND(total_cost, 2)) AS analysis
FROM 
    SupplierCustomerAnalysis
WHERE 
    total_cost > 50000
ORDER BY 
    total_spent DESC, total_cost ASC;
