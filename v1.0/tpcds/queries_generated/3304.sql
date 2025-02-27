
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_purchase
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk, ws.ws_sold_date_sk
),
returns_data AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_returned
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(sd.total_quantity, 0) AS total_quantity_sold,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_returned, 0) AS total_returned,
    CASE 
        WHEN rd.total_returns IS NULL THEN 'No Returns' 
        WHEN rd.total_returned > 0 THEN 'Returned' 
        ELSE 'No Returns' 
    END AS return_status
FROM 
    customer_info ci
LEFT JOIN 
    sales_data sd ON ci.c_customer_id = sd.ws_item_sk
LEFT JOIN 
    returns_data rd ON sd.ws_item_sk = rd.wr_item_sk
WHERE 
    ci.rank_purchase <= 10
ORDER BY 
    ci.cd_gender, ci.cd_purchase_estimate DESC;
