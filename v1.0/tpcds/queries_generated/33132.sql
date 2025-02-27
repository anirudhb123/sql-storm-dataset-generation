
WITH RECURSIVE sales_by_week AS (
    SELECT 
        d.d_year,
        d.d_week_seq,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_week_seq
    UNION ALL
    SELECT 
        d.d_year,
        d.d_week_seq,
        SUM(ws_ext_sales_price) + sbw.total_sales AS total_sales
    FROM 
        sales_by_week sbw
    JOIN 
        date_dim d ON d.d_year = sbw.d_year AND d.d_week_seq = sbw.d_week_seq + 1
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_week_seq
),
subquery_customer AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
filtered_sales AS (
    SELECT 
        sbw.d_year,
        sbw.d_week_seq,
        sbw.total_sales,
        (CASE 
            WHEN COALESCE(cu.order_count, 0) > 10 THEN 'Frequent Buyer' 
            ELSE 'Occasional Buyer' 
         END) AS buyer_type
    FROM 
        sales_by_week sbw
    LEFT JOIN 
        subquery_customer cu ON 1=1
)
SELECT 
    fs.d_year,
    fs.d_week_seq,
    fs.total_sales,
    fs.buyer_type,
    RANK() OVER (PARTITION BY fs.buyer_type ORDER BY fs.total_sales DESC) AS sales_rank
FROM 
    filtered_sales fs
WHERE 
    fs.total_sales > 10000
ORDER BY 
    fs.d_year DESC, fs.d_week_seq DESC;
