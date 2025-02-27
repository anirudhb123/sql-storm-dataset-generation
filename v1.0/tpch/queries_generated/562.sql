WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY total_cost DESC) AS cost_rank
    FROM 
        SupplierStats s
    WHERE 
        total_cost > 1000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_name,
    COALESCE(ts.s_name, 'N/A') AS top_supplier,
    cs.order_count,
    cs.total_spent,
    COALESCE(NULLIF(ts.s_acctbal, 0), 'Account Balance Unavailable') AS s_acctbal
FROM 
    CustomerOrders cs
LEFT JOIN 
    TopSuppliers ts ON cs.order_count > 5 AND ts.cost_rank = 1
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
ORDER BY 
    cs.total_spent DESC;
