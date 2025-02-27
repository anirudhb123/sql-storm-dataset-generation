
WITH DateRange AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_date >= '2023-01-01' AND d_date <= '2023-12-31'
),
SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_net_profit
    FROM web_sales ws
    JOIN DateRange dr ON ws.ws_sold_date_sk = dr.d_date_sk
    GROUP BY ws.web_site_id
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd.cd_credit_rating) AS min_credit_rating,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_id
)
SELECT 
    sd.web_site_id,
    sd.total_quantity,
    sd.total_net_paid,
    sd.total_orders,
    sd.average_net_profit,
    cs.max_purchase_estimate,
    cs.min_credit_rating,
    cs.male_customers,
    cs.female_customers
FROM SalesData sd
JOIN CustomerStats cs ON cs.c_customer_id IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_web_site_sk = sd.web_site_id)
ORDER BY sd.total_net_paid DESC
LIMIT 10;
