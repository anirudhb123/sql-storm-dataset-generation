
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY ws.web_site_sk, ws.web_name
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ISNULL(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
PaymentDetails AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_net_paid_inc_tax) AS total_paid,
        SUM(ws.ws_ext_ship_cost) AS total_shipping
    FROM web_sales ws
    WHERE ws.ws_ship_mode_sk = (SELECT sm.sm_ship_mode_sk FROM ship_mode sm WHERE sm.sm_type = 'Standard')
    GROUP BY ws.ws_order_number
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.buy_potential,
    s.total_net_profit,
    s.total_orders,
    pd.total_paid,
    pd.total_shipping
FROM CustomerInfo ci
JOIN SalesCTE s ON ci.c_customer_sk IN (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_net_profit > 0)
LEFT JOIN PaymentDetails pd ON pd.ws_order_number IN (SELECT ws.ws_order_number FROM web_sales ws WHERE ws.ws_bill_customer_sk = ci.c_customer_sk)
WHERE (ci.buy_potential = 'High' OR ci.cd_gender = 'F') 
AND s.sales_rank <= 10
ORDER BY s.total_net_profit DESC, ci.c_last_name ASC
LIMIT 50;
