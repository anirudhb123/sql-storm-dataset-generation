
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.web_site_id
),
top_websites AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders,
        CASE 
            WHEN total_sales IS NULL THEN 'N/A' 
            ELSE CAST(total_sales AS CHAR)
        END AS sales_value
    FROM 
        sales_summary
    WHERE 
        sales_rank <= 5
),
customer_segment AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
returns_summary AS (
    SELECT 
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_value,
        wr.wr_reason_sk
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_reason_sk
)
SELECT 
    tw.web_site_id,
    tw.total_sales,
    tw.total_orders,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_spent,
    cs.unique_customers,
    rs.total_returns,
    rs.total_return_value
FROM 
    top_websites tw
LEFT JOIN 
    customer_segment cs ON tw.web_site_id = cs.cd_gender OR cs.unique_customers > 1000 
LEFT JOIN 
    returns_summary rs ON rs.total_returns > 0
WHERE 
    (tw.total_sales IS NOT NULL AND tw.total_sales > 1000)
    OR (cs.total_spent IS NULL AND cs.unique_customers = 0)
ORDER BY 
    tw.total_sales DESC, cs.total_spent ASC;
