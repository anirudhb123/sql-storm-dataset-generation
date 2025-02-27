
WITH ranked_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
        AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451555
),
demographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate,
        COUNT(c.c_customer_sk) OVER (PARTITION BY cd.cd_income_band_sk) AS total_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city) AS full_address,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state = 'CA'
),
last_order_info AS (
    SELECT 
        sr.sr_customer_sk,
        MAX(sr.sr_returned_date_sk) AS last_return_date
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
returns_summary AS (
    SELECT 
        lo.sr_customer_sk,
        COUNT(lo.last_return_date) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        last_order_info lo
    LEFT JOIN 
        store_returns sr ON lo.sr_customer_sk = sr.sr_customer_sk AND lo.last_return_date = sr.sr_returned_date_sk
    GROUP BY 
        lo.sr_customer_sk
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    d.cd_income_band_sk,
    d.total_customers,
    r.total_returns,
    r.total_return_amount,
    COUNT(DISTINCT rs.ws_item_sk) AS items_sold,
    SUM(rs.ws_net_profit) AS total_net_profit
FROM 
    demographics d
LEFT JOIN 
    returns_summary r ON d.c_customer_sk = r.sr_customer_sk
LEFT JOIN 
    ranked_sales rs ON rs.ws_sold_date_sk = d.c_customer_sk
GROUP BY 
    d.cd_gender, d.cd_marital_status, d.cd_income_band_sk, r.total_returns, r.total_return_amount
HAVING 
    COUNT(DISTINCT rs.ws_item_sk) > 5
ORDER BY 
    total_net_profit DESC
LIMIT 100;
