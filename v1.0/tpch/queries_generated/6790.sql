WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.n_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
),
CustomerOrders AS (
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
        SUM(o.o_totalprice) > 5000
)
SELECT 
    cu.c_custkey,
    cu.c_name,
    t.r_name AS region,
    t.s_name AS top_supplier,
    t.total_cost,
    cu.total_spent
FROM 
    TopSuppliers t
JOIN 
    CustomerOrders cu ON t.r_name = (SELECT r.r_name FROM region r WHERE r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_name = t.top_supplier LIMIT 1) LIMIT 1))
ORDER BY 
    cu.total_spent DESC, t.total_cost DESC;
