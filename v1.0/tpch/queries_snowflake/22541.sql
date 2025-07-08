
WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY 
        n.n_name, n.n_nationkey
),
TopSales AS (
    SELECT 
        nation_name,
        total_sales
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 3
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(s.total_sales, 0) AS sales_amount
    FROM 
        customer c
    LEFT JOIN 
        TopSales s ON s.nation_name = (
            SELECT n.n_name 
            FROM nation n 
            WHERE n.n_nationkey = c.c_nationkey
        )
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.sales_amount,
    CASE 
        WHEN cs.sales_amount > 1000 THEN 'High Value'
        WHEN cs.sales_amount IS NULL THEN 'No Sales'
        ELSE 'Low Value'
    END AS customer_value_segment,
    os.order_count,
    os.total_spent
FROM 
    CustomerSales cs
LEFT JOIN 
    OrderSummary os ON cs.c_custkey = os.c_custkey
WHERE 
    (os.order_count IS NULL OR os.total_spent > 500)
UNION ALL
SELECT 
    -1 AS c_custkey,
    'Total' AS c_name,
    SUM(cs.sales_amount) AS sales_amount,
    'Aggregated' AS customer_value_segment,
    SUM(os.order_count) AS order_count,
    SUM(os.total_spent) AS total_spent
FROM 
    CustomerSales cs
LEFT JOIN 
    OrderSummary os ON cs.c_custkey = os.c_custkey
HAVING 
    SUM(cs.sales_amount) IS NOT NULL
GROUP BY 
    'Total'
ORDER BY 
    sales_amount DESC;
