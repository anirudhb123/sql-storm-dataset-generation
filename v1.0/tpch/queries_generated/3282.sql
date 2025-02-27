WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_spent
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                CustomerOrders
        )
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    s.s_name,
    COALESCE(c.c_name, 'No Customer') AS customer_name,
    SUM(l.revenue) AS total_revenue,
    SUM(ss.total_cost) AS supplier_cost,
    SUM(CASE WHEN c.c_custkey IS NOT NULL THEN l.revenue ELSE 0 END) AS customer_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    HighValueCustomers c ON s.s_suppkey = c.c_custkey
JOIN 
    SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
WHERE 
    p.p_size BETWEEN 10 AND 50
GROUP BY 
    r.r_name, s.s_name, c.c_name
ORDER BY 
    total_revenue DESC, supplier_cost ASC
LIMIT 100;
