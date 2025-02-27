
WITH RECURSIVE CustomerSalesCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sales_price IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING total_profit > 0
    UNION ALL
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit + ws.ws_net_profit,
        cs.order_count + 1
    FROM CustomerSalesCTE cs
    JOIN web_sales ws ON cs.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_net_profit IS NOT NULL AND ws.ws_item_sk IS NOT NULL
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_profit,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM CustomerSalesCTE cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_profit,
    hvc.order_count,
    COALESCE(su.shipping_cost, 0) AS shipping_cost,
    COALESCE(su.tax_amount, 0) AS tax_amount
FROM HighValueCustomers hvc
LEFT JOIN (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_ext_ship_cost) AS shipping_cost,
        SUM(ws.ws_ext_tax) AS tax_amount
    FROM web_sales ws
    GROUP BY ws.ws_ship_customer_sk
) su ON hvc.c_customer_sk = su.ws_ship_customer_sk
WHERE hvc.rank <= 10
ORDER BY hvc.total_profit DESC;
