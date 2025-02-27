WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 10
    GROUP BY 
        ps.ps_partkey
), 
RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        total_spent,
        order_count,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerOrders c
    WHERE 
        total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    rc.c_name,
    rc.total_spent,
    ps.total_supply_cost,
    ts.s_name AS top_supplier_name
FROM 
    RankedCustomers rc
LEFT JOIN 
    PartSuppliers ps ON ps.ps_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_custkey = rc.c_custkey
    )
LEFT JOIN 
    TopSuppliers ts ON ts.supplier_rank = 1
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.total_spent DESC;
