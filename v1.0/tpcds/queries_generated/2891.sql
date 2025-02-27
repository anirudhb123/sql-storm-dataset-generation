
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= CURRENT_DATE)
    GROUP BY 
        ws.ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 100 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
returns_stats AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        sr_item_sk
)

SELECT 
    r.ws_item_sk,
    COALESCE(rs.total_quantity, 0) AS sold_quantity,
    COALESCE(rs.total_sales, 0) AS sold_sales,
    COALESCE(rt.return_count, 0) AS return_count,
    COALESCE(rt.total_return_amt, 0) AS total_return_amount,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.purchase_category
FROM 
    ranked_sales rs
LEFT JOIN 
    returns_stats rt ON rs.ws_item_sk = rt.sr_item_sk
JOIN 
    customer_info ci ON ci.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = rs.ws_item_sk LIMIT 1)
WHERE 
    rs.sales_rank = 1
ORDER BY 
    sold_sales DESC, 
    ci.c_last_name, 
    ci.c_first_name
LIMIT 100;
