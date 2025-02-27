
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
AddressedReturns AS (
    SELECT 
        sr.sr_customer_sk,
        sr.sr_ticket_number,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns AS sr
    GROUP BY sr.sr_customer_sk, sr.sr_ticket_number
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        ar.total_returns,
        ar.total_return_value
    FROM RankedCustomers AS rc
    LEFT JOIN AddressedReturns AS ar ON rc.c_customer_sk = ar.sr_customer_sk
    WHERE rc.rank <= 10
),
SalesByWarehouse AS (
    SELECT 
        ws.ws_warehouse_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales AS ws
    GROUP BY ws.ws_warehouse_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    COALESCE(ar.total_returns, 0) AS total_returns,
    COALESCE(ar.total_return_value, 0) AS total_return_value,
    COALESCE(sw.total_orders, 0) AS total_orders,
    COALESCE(sw.total_profit, 0) AS total_profit
FROM TopCustomers AS tc
LEFT JOIN SalesByWarehouse AS sw ON sw.ws_warehouse_sk IN (
    SELECT w.w_warehouse_sk 
    FROM warehouse AS w 
    JOIN web_sales AS ws ON ws.ws_warehouse_sk = w.w_warehouse_sk 
    WHERE ws.ws_bill_customer_sk = tc.c_customer_sk
)
ORDER BY total_return_value DESC, total_returns DESC;
