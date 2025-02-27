
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS rank
    FROM web_sales ws
    WHERE ws.ship_date_sk IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returns,
        COUNT(DISTINCT cr.order_number) AS return_count
    FROM catalog_returns cr
    GROUP BY cr.returning_customer_sk
),
ProductSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS average_price,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT 
    ca.ca_address_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
    AVG(ws.ws_sales_price) AS average_sales_price,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COUNT(DISTINCT ws.ws_ship_date_sk) AS shipping_days,
    MAX(RS.rank) AS rank
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
JOIN RankedSales RS ON ws.web_site_sk = RS.web_site_sk
WHERE (cd.cd_gender = 'M' OR cd.cd_marital_status = 'M')
  AND cd.cd_credit_rating IS NOT NULL
GROUP BY 
    ca.ca_address_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating
HAVING 
    SUM(ws.ws_net_paid_inc_tax) > 1000
ORDER BY 
    total_net_paid DESC;
