WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_orders,
        c.total_spent,
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders c
    WHERE 
        c.total_orders > 10
)
SELECT 
    rs.s_name AS supplier_name,
    r.n_name AS nation_name,
    tc.c_name AS customer_name,
    tc.total_spent,
    tc.total_orders,
    rs.total_supply_cost
FROM 
    RankedSuppliers rs
JOIN 
    nation r ON rs.s_nationkey = r.n_nationkey
JOIN 
    TopCustomers tc ON rs.rank <= 5
ORDER BY 
    rs.total_supply_cost DESC, tc.total_spent DESC;
