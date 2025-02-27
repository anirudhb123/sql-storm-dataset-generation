WITH RankedSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        SUM(ps_supplycost * ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps_supplycost * ps_availqty) DESC) AS rank
    FROM 
        supplier
    JOIN 
        partsupp ON s_suppkey = ps_suppkey
    GROUP BY 
        s_suppkey, s_name
),
TopSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        total_supply_cost
    FROM 
        RankedSuppliers
    WHERE 
        rank <= 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
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
        c_custkey,
        c_name,
        order_count,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerOrders
    WHERE 
        order_count > 5
)
SELECT 
    tc.c_name AS customer_name,
    tc.total_spent,
    ts.s_name AS supplier_name,
    ts.total_supply_cost
FROM 
    TopCustomers tc
JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_custkey)
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE 
    l.l_returnflag = 'N'
ORDER BY 
    tc.total_spent DESC, ts.total_supply_cost DESC;
