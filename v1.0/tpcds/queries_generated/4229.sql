
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20230101 AND 20231231
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        SUM(rs.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM RankedSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    WHERE rs.rank <= 10
    GROUP BY rs.ws_item_sk, i.i_item_desc
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        h.hd_buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
    WHERE cd.cd_gender IS NOT NULL
),
SalesWithCustomer AS (
    SELECT 
        s.ws_order_number,
        ci.c_customer_id,
        ti.total_net_profit
    FROM web_sales s
    JOIN CustomerInfo ci ON s.ws_bill_customer_sk = ci.c_customer_sk
    JOIN TopItems ti ON s.ws_item_sk = ti.ws_item_sk
)
SELECT 
    ci.c_customer_id,
    SUM(swc.total_net_profit) AS customer_total_net_profit,
    COUNT(DISTINCT swc.ws_order_number) AS total_orders,
    COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status
FROM SalesWithCustomer swc
JOIN customer_demographics cd ON ci.c_customer_id = cd.cd_demo_sk
GROUP BY ci.c_customer_id, cd.cd_marital_status
HAVING customer_total_net_profit > 10000
ORDER BY customer_total_net_profit DESC
LIMIT 100;
