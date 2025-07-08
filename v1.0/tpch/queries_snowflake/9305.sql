
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
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
        r.nation_name,
        r.s_suppkey,
        r.s_name,
        r.total_supply_cost
    FROM 
        RankedSuppliers r
    WHERE 
        r.rank <= 5
),
OrderStats AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
)

SELECT 
    c.c_name AS customer_name,
    o.total_orders,
    o.total_spent,
    ts.nation_name,
    ts.s_name AS top_supplier_name,
    ts.total_supply_cost
FROM 
    customer c
JOIN 
    OrderStats o ON c.c_custkey = o.o_custkey
JOIN 
    TopSuppliers ts ON ts.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = c.c_nationkey LIMIT 1)
WHERE 
    o.total_spent > 1000
ORDER BY 
    o.total_spent DESC;
