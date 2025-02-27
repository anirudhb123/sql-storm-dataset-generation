
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ca.ca_city, 
        ca.ca_state, 
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_last_name) AS rn 
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
), TopItems AS (
    SELECT 
        item.i_item_sk, 
        item.i_product_name, 
        item.i_current_price, 
        RANK() OVER (ORDER BY SUM(ss_net_profit) DESC) AS rank 
    FROM 
        store_sales ss 
    JOIN 
        item item ON ss.ss_item_sk = item.i_item_sk 
    WHERE 
        ss.sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
    GROUP BY 
        item.i_item_sk, item.i_product_name, item.i_current_price 
    HAVING 
        SUM(ss.ss_net_profit) > 5000 
)
SELECT 
    ci.c_customer_sk, 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.ca_city, 
    ci.ca_state, 
    ti.i_product_name, 
    ti.i_current_price, 
    COALESCE(sc.total_net_profit, 0) AS total_net_profit 
FROM 
    CustomerInfo ci 
LEFT JOIN 
    SalesCTE sc ON ci.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk IN (SELECT i_item_sk FROM TopItems) LIMIT 1)
JOIN 
    TopItems ti ON ti.i_item_sk = sc.ws_item_sk 
WHERE 
    ci.rn = 1 
AND 
    sc.rn = 1 
ORDER BY 
    ci.c_last_name, ti.i_product_name;
