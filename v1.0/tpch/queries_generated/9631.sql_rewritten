WITH regional_sales AS (
    SELECT 
        r.r_name AS region,
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
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
        AND l.l_shipmode IN ('AIR', 'TRUCK')
    GROUP BY 
        r.r_name
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
)
SELECT 
    rs.region,
    cs.c_custkey,
    cs.c_name,
    cs.total_spent,
    rs.total_sales,
    (cs.total_spent / NULLIF(rs.total_sales, 0)) * 100 AS customer_contribution_percentage
FROM 
    regional_sales rs
JOIN 
    customer_summary cs ON rs.region = (
        SELECT r.r_name
        FROM region r
        JOIN nation n ON r.r_regionkey = n.n_regionkey
        JOIN customer c ON n.n_nationkey = c.c_nationkey
        WHERE c.c_custkey = cs.c_custkey
    )
ORDER BY 
    rs.region, cs.total_spent DESC;