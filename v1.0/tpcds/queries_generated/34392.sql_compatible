
WITH RECURSIVE sales_data AS (
    SELECT 
        ss_item_sk, 
        SUM(ss_quantity) AS total_quantity, 
        SUM(ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM store_sales
    GROUP BY ss_item_sk
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        ROW_NUMBER() OVER (ORDER BY inv.inv_quantity_on_hand DESC) AS rank
    FROM inventory inv
),
customer_data AS (
    SELECT 
        CD.c_customer_sk,
        CD.cd_gender,
        CD.cd_marital_status,
        COALESCE(SUM(WS.ws_net_profit), 0) AS total_profit,
        COUNT(WS.ws_order_number) AS orders_count
    FROM customer CD
    LEFT JOIN web_sales WS ON CD.c_customer_sk = WS.ws_bill_customer_sk
    GROUP BY CD.c_customer_sk, CD.cd_gender, CD.cd_marital_status
),
high_value_customers AS (
    SELECT *
    FROM customer_data
    WHERE total_profit > (SELECT AVG(total_profit) FROM customer_data)
)
SELECT 
    CA.ca_country, 
    CA.ca_state,
    HD.hd_income_band_sk,
    COUNT(DISTINCT C.c_customer_sk) AS customers_count,
    SUM(SD.total_net_profit) AS total_sales_profit,
    AVG(SD.total_quantity) AS avg_quantity_sold,
    MAX(I.inv_quantity_on_hand) AS max_inventory
FROM customer_address CA
JOIN customer C ON C.c_current_addr_sk = CA.ca_address_sk
LEFT JOIN high_value_customers HVC ON C.c_customer_sk = HVC.c_customer_sk
JOIN sales_data SD ON SD.ss_item_sk = C.c_current_hdemo_sk
LEFT JOIN inventory_data I ON I.inv_item_sk = C.c_current_hdemo_sk
JOIN household_demographics HD ON HD.hd_demo_sk = C.c_current_hdemo_sk
GROUP BY CA.ca_country, CA.ca_state, HD.hd_income_band_sk
HAVING COUNT(DISTINCT C.c_customer_sk) > 10
ORDER BY total_sales_profit DESC;
