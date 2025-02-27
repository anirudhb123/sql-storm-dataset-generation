
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        COUNT(*) AS sales_count,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (
            SELECT 
                MIN(d_date_sk) 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023
        ) AND (
            SELECT 
                MAX(d_date_sk) 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023
        )
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_total_sales) AS customer_total_sales,
        COUNT(ws_item_sk) AS items_purchased
    FROM 
        sales_data sd
    JOIN 
        web_sales ws ON sd.ws_item_sk = ws.ws_item_sk AND sd.ws_sold_date_sk = ws.ws_sold_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        cs.customer_total_sales,
        DENSE_RANK() OVER (ORDER BY cs.customer_total_sales DESC) AS rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.customer_total_sales > 10000
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    hvc.customer_total_sales,
    COALESCE(r.r_reason_desc, 'No Reason') AS return_reason,
    ROW_NUMBER() OVER (PARTITION BY hvc.customer_total_sales ORDER BY hvc.rank) AS row_number
FROM 
    high_value_customers hvc
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = hvc.c_customer_sk)
LEFT JOIN 
    store_returns sr ON hvc.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND hvc.customer_total_sales BETWEEN 10000 AND 50000
ORDER BY 
    hvc.customer_total_sales DESC, row_number;
