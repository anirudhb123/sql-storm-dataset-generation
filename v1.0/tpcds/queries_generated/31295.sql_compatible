
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        item.i_item_desc,
        sales.total_sales
    FROM 
        sales_cte sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.sales_rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(sr.ticket_number) AS return_count,
        SUM(sr.return_amt) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
high_return_customers AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.return_count,
        ci.total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY ci.total_return_amount DESC) AS return_rank
    FROM 
        customer_info ci
    WHERE 
        ci.total_return_amount IS NOT NULL
        AND ci.return_count > 0
)
SELECT 
    tsi.i_item_desc,
    hrc.c_customer_id,
    hrc.cd_gender,
    hrc.cd_marital_status,
    hrc.total_return_amount
FROM 
    top_sales tsi
JOIN 
    high_return_customers hrc ON hrc.return_rank <= 5
WHERE 
    hrc.cd_marital_status = 'M'
ORDER BY 
    tsi.total_sales DESC, hrc.total_return_amount DESC;
