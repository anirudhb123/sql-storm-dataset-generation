
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(co.total_spent) AS total_spent,
        RANK() OVER (ORDER BY SUM(co.total_spent) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rc.s_suppkey,
    rc.s_name,
    rc.total_supply_cost,
    tc.c_custkey,
    tc.c_name,
    tc.total_spent
FROM 
    RankedSuppliers rc
JOIN 
    TopCustomers tc ON rc.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_orderkey IN (
            SELECT o.o_orderkey 
            FROM orders o 
            JOIN customer c ON o.o_custkey = c.c_custkey
            WHERE c.c_custkey = tc.c_custkey
        )
        GROUP BY ps.ps_suppkey
        ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC
        LIMIT 1
    )
WHERE 
    rc.supplier_rank <= 10 
    AND tc.customer_rank <= 10
ORDER BY 
    rc.total_supply_cost DESC, tc.total_spent DESC;
