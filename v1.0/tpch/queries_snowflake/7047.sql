WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
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
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(co.total_spent) AS total_revenue
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        n.n_regionkey, r.r_name
    ORDER BY 
        total_revenue DESC
    LIMIT 5
)
SELECT 
    tr.r_name,
    tr.customer_count,
    tr.total_revenue,
    sc.total_supply_cost
FROM 
    TopRegions tr
JOIN 
    SupplierCosts sc ON EXISTS (
        SELECT 1
        FROM supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        WHERE s.s_nationkey IN (
            SELECT n.n_nationkey
            FROM nation n
            WHERE n.n_regionkey = tr.n_regionkey
        )
    )
ORDER BY 
    tr.total_revenue DESC;
