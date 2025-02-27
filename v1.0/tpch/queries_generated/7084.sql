WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplier_cost,
        COUNT(DISTINCT ps.ps_partkey) AS number_of_parts
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
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supplier_cost,
        ss.number_of_parts,
        RANK() OVER (ORDER BY ss.total_supplier_cost DESC) AS rank
    FROM 
        supplier s
    JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_orders,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        customer_orders co
)
SELECT 
    ts.s_name AS supplier_name,
    tc.c_name AS customer_name,
    ts.total_supplier_cost,
    tc.total_spent
FROM 
    TopSuppliers ts
JOIN 
    TopCustomers tc ON ts.rank = tc.rank
WHERE 
    ts.number_of_parts > 10 AND tc.total_orders > 5
ORDER BY 
    ts.rank;
