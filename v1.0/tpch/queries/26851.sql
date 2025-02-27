WITH CustomerDetails AS (
    SELECT 
        c.c_name,
        c.c_address,
        r.r_name AS region,
        n.n_name AS nation,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT p.p_name, ', ') AS purchased_products
    FROM 
        customer c
    JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        c.c_name, c.c_address, r.r_name, n.n_name
)
SELECT 
    region,
    COUNT(DISTINCT c_name) AS num_customers,
    SUM(total_orders) AS total_orders,
    SUM(total_spent) AS total_revenue,
    STRING_AGG(DISTINCT purchased_products, '; ') AS all_products_purchased
FROM 
    CustomerDetails
GROUP BY 
    region
ORDER BY 
    total_revenue DESC;
