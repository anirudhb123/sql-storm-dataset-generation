WITH RECURSIVE sales_summary AS (
    SELECT 
        su.s_suppkey,
        su.s_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY su.s_suppkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS sales_rank
    FROM 
        supplier su
    JOIN 
        partsupp ps ON su.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem li ON li.l_partkey = p.p_partkey
    GROUP BY 
        su.s_suppkey, su.s_name
),
top_suppliers AS (
    SELECT 
        s_suppkey,
        s_name
    FROM 
        sales_summary
    WHERE 
        sales_rank <= 10
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.s_name,
    co.c_name,
    co.total_orders,
    co.total_spent,
    CASE 
        WHEN co.total_spent IS NULL OR co.total_spent = 0 THEN 'No Spending'
        ELSE 'Active Customer' 
    END AS customer_status,
    COUNT(DISTINCT co.c_custkey) OVER () AS total_customers,
    (SELECT AVG(total_spent) FROM customer_orders) AS avg_customer_spending
FROM 
    top_suppliers ts
LEFT JOIN 
    customer_orders co ON co.c_custkey IN (
        SELECT o.o_custkey
        FROM orders o
        JOIN lineitem li ON li.l_orderkey = o.o_orderkey
        WHERE li.l_suppkey = ts.s_suppkey
    )
ORDER BY 
    ts.s_name, co.total_spent DESC;
