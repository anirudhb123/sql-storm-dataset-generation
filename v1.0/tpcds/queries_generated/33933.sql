
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_order_number, 
        ws_item_sk, 
        ws_quantity, 
        ws_sales_price, 
        ws_ext_sales_price,
        ws_ext_tax,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_order_number) AS row_num
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458122 AND 2458129
),
return_data AS (
    SELECT
        wr_order_number,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_order_number
),
combined_sales AS (
    SELECT 
        sd.ws_order_number,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_ext_sales_price) AS total_sales,
        COALESCE(rd.total_returned, 0) AS total_returned,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        SUM(sd.ws_ext_sales_price - sd.ws_ext_tax) AS net_sales
    FROM 
        sales_data sd
    LEFT JOIN 
        return_data rd 
    ON 
        sd.ws_order_number = rd.wr_order_number
    GROUP BY 
        sd.ws_order_number
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.c_email_address,
    cs.c_preferred_cust_flag,
    cs.c_birth_day,
    cs.c_birth_month,
    cs.c_birth_year,
    s.store_name,
    SUM(cs.total_sales) AS total_sales,
    SUM(cs.total_returned) AS total_returns,
    COUNT(cs.total_returned) FILTER (WHERE cs.total_returned > 0) AS return_count,
    MAX(cs.net_sales) AS max_net_sale,
    MIN(cs.net_sales) AS min_net_sale
FROM 
    combined_sales cs
JOIN 
    customer c ON c.c_customer_sk = cs.ws_order_number
JOIN 
    store s ON s.s_store_sk = cs.ws_item_sk
WHERE 
    c.c_birth_year IS NOT NULL
    AND (c.c_birth_month = 1 OR c.c_birth_month = 2)
GROUP BY 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.c_email_address,
    cs.c_preferred_cust_flag,
    cs.c_birth_day,
    cs.c_birth_month,
    cs.c_birth_year,
    s.store_name
ORDER BY 
    total_sales DESC
LIMIT 10;
