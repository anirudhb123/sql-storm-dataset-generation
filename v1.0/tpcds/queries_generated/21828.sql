
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        d.d_date_id,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id, d.d_date_id
    HAVING 
        SUM(ws.ws_sales_price) > (SELECT AVG(ws2.ws_sales_price) 
                                   FROM web_sales ws2 
                                   WHERE ws2.ws_sold_date_sk BETWEEN d.d_date_sk - 30 AND d.d_date_sk)
),

SalesSummary AS (
    SELECT 
        r.c_customer_id,
        r.total_sales,
        CASE 
            WHEN r.sales_rank = 1 THEN 'Top Performer' 
            ELSE 'Regular'
        END AS customer_category
    FROM 
        RankedSales r
)

SELECT 
    s.customer_category,
    COUNT(s.c_customer_id) AS customer_count,
    SUM(s.total_sales) AS aggregated_sales,
    AVG(s.total_sales) AS average_sales_per_customer,
    MAX(s.total_sales) AS max_sales,
    MIN(s.total_sales) AS min_sales
FROM 
    SalesSummary s
LEFT JOIN 
    customer_demographics cd ON s.c_customer_id = cd.cd_demo_sk
WHERE 
    (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M') 
    OR (cd.cd_gender = 'M' AND cd.cd_marital_status IS NOT NULL)
GROUP BY 
    s.customer_category
ORDER BY 
    aggregated_sales DESC
FETCH FIRST 10 ROWS ONLY;
