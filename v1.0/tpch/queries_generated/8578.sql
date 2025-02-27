WITH RankedSuppliers AS (
    SELECT 
        s_name, 
        s_suppkey, 
        SUM(ps_supplycost * ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps_supplycost * ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_name, s.s_suppkey, n.n_name
),
TopSuppliers AS (
    SELECT 
        * 
    FROM 
        RankedSuppliers 
    WHERE 
        rn <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
)
SELECT 
    to.c_name AS customer_name,
    COUNT(to.o_orderkey) AS total_orders,
    SUM(to.o_totalprice) AS total_spent,
    ts.s_name AS supplier_name,
    ts.total_supply_cost
FROM 
    CustomerOrders to
JOIN 
    lineitem li ON to.o_orderkey = li.l_orderkey
JOIN 
    TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
GROUP BY 
    to.c_name, ts.s_name
ORDER BY 
    total_spent DESC, customer_name ASC;
