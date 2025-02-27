WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        s.total_cost,
        p.p_name
    FROM 
        RankedSuppliers s
    JOIN 
        part p ON s.p_partkey = p.p_partkey
    WHERE 
        s.rank = 1
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
        SUM(o.o_totalprice) > 10000
)
SELECT 
    co.c_name AS customer_name,
    COALESCE(ts.p_name, 'No Orders') AS part_name,
    COALESCE(ts.total_cost, 0) AS supplier_total_cost,
    co.total_spent AS customer_total_spent
FROM 
    CustomerOrders co
LEFT JOIN 
    TopSuppliers ts ON co.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_custkey = co.c_custkey))
ORDER BY 
    co.total_spent DESC, ts.total_cost DESC;
