
WITH RECURSIVE sales_data AS (
    SELECT 
        cs_order_number,
        cs_sold_date_sk,
        cs_quantity,
        cs_sales_price,
        cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_order_number ORDER BY cs_sold_date_sk) AS rn
    FROM 
        catalog_sales
    UNION ALL
    SELECT 
        ws_order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sold_date_sk) AS rn
    FROM 
        web_sales
),
customer_summary AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        cd.cd_gender,
        SUM(sd.cs_sales_price) AS total_sales,
        COUNT(DISTINCT sd.cs_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_data sd ON c.c_customer_sk = sd.cs_order_number
    GROUP BY 
        c.customer_id, c.first_name, c.last_name, cd.cd_gender
    HAVING 
        SUM(sd.cs_sales_price) > 1000
),
top_customers AS (
    SELECT 
        customer_id,
        first_name,
        last_name,
        cd_gender,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_summary
)
SELECT 
    tc.customer_id,
    tc.first_name,
    tc.last_name,
    tc.cd_gender,
    tc.total_sales,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top Performer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    top_customers tc
WHERE 
    tc.cd_gender IS NOT NULL
    AND EXISTS (
        SELECT 1 
        FROM store s 
        WHERE s.s_closed_date_sk IS NULL 
        AND s.s_store_sk = (
            SELECT MIN(s_store_sk) 
            FROM store
        )
    )
ORDER BY 
    tc.total_sales DESC;
