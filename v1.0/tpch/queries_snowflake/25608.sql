WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_in_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_name,
        n.n_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank_in_nation <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.s_name AS supplier_name,
    ts.n_name AS nation_name,
    co.c_name AS customer_name,
    co.total_orders,
    co.total_spent,
    ts.total_cost
FROM 
    TopSuppliers ts
JOIN 
    CustomerOrders co ON ts.n_name = (SELECT n_name FROM nation WHERE n_nationkey = (SELECT DISTINCT c_nationkey FROM customer WHERE c_name = co.c_name))
ORDER BY 
    ts.total_cost DESC, co.total_spent DESC;
