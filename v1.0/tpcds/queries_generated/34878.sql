
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
ranked_sales AS (
    SELECT 
        ws_item_sk, 
        total_quantity, 
        total_sales, 
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank 
    FROM 
        sales_summary
), 
top_sales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.total_quantity, 
        rs.total_sales, 
        i.i_item_desc, 
        i.i_current_price, 
        CASE 
            WHEN cd_marital_status LIKE 'S%' THEN 'Single' 
            ELSE 'Married' 
        END AS marital_status,
        (SELECT COUNT(DISTINCT ws_bill_customer_sk) 
         FROM web_sales 
         WHERE ws_item_sk = rs.ws_item_sk) AS unique_customers
    FROM 
        ranked_sales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        customer c ON c.c_customer_sk = (SELECT TOP 1 ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = rs.ws_item_sk)
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        rs.sales_rank <= 10
)

SELECT 
    ts.ws_item_sk, 
    ts.total_quantity, 
    ts.total_sales, 
    ts.i_item_desc, 
    ts.i_current_price, 
    ts.marital_status,
    ts.unique_customers,
    CASE 
        WHEN ts.total_sales IS NULL THEN 'No Sales' 
        ELSE 'Sales Recorded' 
    END AS sales_status
FROM 
    top_sales ts
ORDER BY 
    ts.total_sales DESC;

