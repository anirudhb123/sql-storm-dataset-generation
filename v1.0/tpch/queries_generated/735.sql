WITH region_sales AS (
    SELECT 
        r.r_name AS region_name,
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
        r.r_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
ranked_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS customer_rank
    FROM 
        customer_orders c
),
selected_customers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name
    FROM 
        ranked_customers cust
    WHERE 
        cust.customer_rank <= 10
)
SELECT 
    r.region_name,
    COALESCE(s.total_sales, 0) AS total_sales,
    COUNT(DISTINCT sc.c_custkey) AS top_customers_count
FROM 
    region_sales s
FULL OUTER JOIN 
    selected_customers sc ON s.region_name = (
        SELECT 
            n.r_name 
        FROM 
            nation n
        JOIN 
            supplier st ON n.n_nationkey = st.s_nationkey
        WHERE 
            st.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p))
        LIMIT 1
    )
GROUP BY 
    r.region_name
ORDER BY 
    total_sales DESC;
