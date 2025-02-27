WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_size > 10 
        AND s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        ci.c_name,
        ci.order_count,
        ci.total_spent
    FROM 
        CustomerOrders ci
    JOIN 
        customer c ON ci.c_custkey = c.c_custkey
    WHERE 
        ci.total_spent > (
            SELECT AVG(total_spent) FROM CustomerOrders
        )
)
SELECT 
    n.n_name, 
    rs.s_name, 
    rs.total_cost,
    hvc.c_name,
    hvc.total_spent
FROM 
    RankedSuppliers rs
FULL OUTER JOIN 
    HighValueCustomers hvc ON rs.rank = 1 
JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
WHERE 
    rs.total_cost IS NOT NULL 
    OR hvc.total_spent IS NOT NULL
ORDER BY 
    n.n_name, 
    rs.total_cost DESC NULLS LAST;
