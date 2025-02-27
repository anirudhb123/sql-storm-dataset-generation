
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        MAX(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS max_profit
    FROM 
        web_sales ws
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(COALESCE(rs.ws_sales_price, 0)) AS total_sales,
    AVG(CASE WHEN cd.cd_marital_status = 'M' THEN rs.ws_sales_price ELSE NULL END) AS avg_sales_married,
    COUNT(DISTINCT cd.c_customer_sk) AS unique_customers
FROM 
    customer_address ca
LEFT JOIN RankedSales rs ON rs.ws_item_sk IN (
    SELECT ir.ws_item_sk
    FROM RankedSales ir
    WHERE ir.price_rank = 1
)
INNER JOIN CustomerDetails cd ON ca.ca_address_sk = cd.c_customer_sk
WHERE 
    ca.ca_state IS NOT NULL
    AND (cd.cd_gender = 'F' OR cd.cd_purchase_estimate > 500)
GROUP BY 
    ca.ca_city, 
    ca.ca_state
HAVING 
    SUM(COALESCE(rs.ws_sales_price, 0)) > 1000
    AND COUNT(DISTINCT cd.c_customer_sk) > 5
ORDER BY 
    ca.ca_state, 
    total_sales DESC
LIMIT 10;
