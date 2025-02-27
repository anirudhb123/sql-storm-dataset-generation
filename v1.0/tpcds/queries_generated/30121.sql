
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(NULLIF(d.cd_gender, ''), 'Unknown') AS gender,
        COALESCE(NULLIF(d.cd_marital_status, ''), 'S') AS marital_status,
        d.cd_credit_rating,
        d.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
inventory_summary AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        AVG(i.i_current_price) AS avg_price,
        COUNT(DISTINCT i.i_brand) AS unique_brands
    FROM 
        item AS i
    JOIN 
        inventory AS inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk
),
sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim AS d) 
        AND ws.ws_sold_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim AS d)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
return_data AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    h.c_customer_id,
    h.gender,
    h.marital_status,
    h.cd_credit_rating,
    h.cd_purchase_estimate,
    COALESCE(sd.total_sold, 0) AS total_sold,
    COALESCE(sd.total_revenue, 0) AS total_revenue,
    COALESCE(is.total_quantity, 0) AS total_quantity_on_hand,
    COALESCE(is.avg_price, 0) AS avg_price,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_return_value, 0) AS total_return_value,
    CASE 
        WHEN COALESCE(sd.total_sold, 0) > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END AS customer_status
FROM 
    sales_hierarchy AS h
LEFT JOIN 
    sales_data AS sd ON h.c_customer_sk = sd.ws_item_sk
LEFT JOIN 
    inventory_summary AS is ON sd.ws_item_sk = is.i_item_sk
LEFT JOIN 
    return_data AS rd ON sd.ws_item_sk = rd.sr_item_sk
WHERE 
    h.purchase_rank = 1
AND 
    (h.cd_purchase_estimate >= 500 OR h.cd_credit_rating = 'High')
ORDER BY 
    total_revenue DESC
LIMIT 100;
