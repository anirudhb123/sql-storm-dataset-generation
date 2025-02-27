
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
WebSalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        w.web_name
    FROM 
        web_sales AS ws
    JOIN 
        web_site AS w ON ws.ws_web_site_sk = w.web_site_sk
),
SalesSummary AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        SUM(wsi.ws_sales_price * wsi.ws_quantity) AS total_sales,
        COUNT(wsi.ws_order_number) AS total_orders,
        SUM(wsi.ws_net_profit) AS total_net_profit
    FROM 
        CustomerInfo AS ci
    JOIN 
        WebSalesInfo AS wsi ON ci.c_customer_id = wsi.ws_order_number
    GROUP BY 
        ci.c_customer_id, ci.full_name, ci.cd_gender, ci.cd_marital_status
)
SELECT 
    ss.c_customer_id,
    ss.full_name,
    ss.cd_gender,
    ss.cd_marital_status,
    ss.total_sales,
    ss.total_orders,
    ss.total_net_profit,
    CASE 
        WHEN ss.total_net_profit > 1000 THEN 'High Value'
        WHEN ss.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    SalesSummary AS ss
ORDER BY 
    total_sales DESC
LIMIT 50;
