WITH RECURSIVE regional_sales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        total_sales > (SELECT AVG(total_sales) FROM 
            (SELECT 
                SUM(l_extendedprice * (1 - l_discount)) AS total_sales 
            FROM 
                lineitem 
            GROUP BY 
                l_orderkey) AS avg_sales)
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    cs.c_name,
    cs.total_order_value,
    COALESCE(rs.total_sales, 0) AS region_sales
FROM 
    customer_orders cs
LEFT JOIN 
    regional_sales rs ON cs.c_name LIKE '%' || rs.r_name || '%'
WHERE 
    cs.rn = 1
ORDER BY 
    region_sales DESC, total_order_value DESC
LIMIT 10;
