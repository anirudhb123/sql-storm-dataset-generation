
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
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
),
QualifiedCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COALESCE(co.total_spent, 0) AS total_spent,
        RANK() OVER (ORDER BY COALESCE(co.total_spent, 0) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
),
HighSpendingCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name
    FROM 
        QualifiedCustomers c
    WHERE 
        c.customer_rank <= 10
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT cs.c_custkey) AS num_customers,
    SUM(rk.total_supply_cost) AS total_cost,
    AVG(rk.total_supply_cost) AS avg_cost_per_supplier
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    RankedSuppliers rk ON rk.s_suppkey = s.s_suppkey
LEFT JOIN 
    HighSpendingCustomers cs ON cs.c_custkey = (
        SELECT DISTINCT o.o_custkey
        FROM orders o 
        JOIN lineitem li ON o.o_orderkey = li.l_orderkey 
        WHERE li.l_suppkey = s.s_suppkey 
        LIMIT 1
    )
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
