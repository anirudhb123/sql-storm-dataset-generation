WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.nation_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rn <= 5
),
CustomersWithOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
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
        c.total_order_value,
        RANK() OVER (ORDER BY c.total_order_value DESC) AS cust_rank
    FROM 
        CustomersWithOrders c
    WHERE 
        c.total_order_value IS NOT NULL
)
SELECT 
    tc.c_name AS top_customer_name,
    ts.region_name,
    ts.s_name AS top_supplier_name,
    ts.total_supply_cost,
    tc.total_order_value
FROM 
    TopCustomers tc
JOIN 
    TopSuppliers ts ON tc.c_custkey = ts.s_suppkey
WHERE 
    ts.total_supply_cost > (
        SELECT AVG(total_supply_cost) 
        FROM TopSuppliers
    )
ORDER BY 
    tc.total_order_value DESC, ts.total_supply_cost DESC
LIMIT 10;
