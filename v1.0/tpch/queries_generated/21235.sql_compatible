
WITH aggregated_sales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        c.c_custkey
),
ranked_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        a.total_spent,
        a.total_orders,
        RANK() OVER (ORDER BY a.total_spent DESC) AS rank
    FROM 
        aggregated_sales a
    JOIN 
        customer c ON a.c_custkey = c.c_custkey
    WHERE 
        a.total_orders > 3
),
region_details AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nations
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT rc.c_custkey) AS high_spending_customers,
    AVG(rc.total_spent) AS avg_spent,
    MAX(rc.total_spent) AS max_spent,
    COALESCE(MIN(rc.total_orders), 0) AS min_orders,
    STRING_AGG(n.nations ORDER BY n.nation_count DESC) AS active_nations
FROM 
    ranked_customers rc
LEFT JOIN 
    region_details n ON rc.c_custkey % 10 = n.nation_count  
LEFT JOIN 
    nation na ON na.n_nationkey = rc.c_custkey % 5  
JOIN 
    region r ON na.n_regionkey = r.r_regionkey
WHERE 
    rc.rank <= 10
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT rc.c_custkey) > 0
ORDER BY 
    max_spent DESC, r.r_name ASC
LIMIT 5;
