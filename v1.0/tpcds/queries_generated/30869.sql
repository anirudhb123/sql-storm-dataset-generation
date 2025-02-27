
WITH RECURSIVE item_sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_paid) AS total_sales_amount,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        (
            SELECT COUNT(*)
            FROM web_sales ws
            WHERE ws.ws_bill_customer_sk = c.c_customer_sk
        ) AS purchase_count,
        (
            SELECT COUNT(*) 
            FROM store_sales ss 
            WHERE ss.ss_customer_sk = c.c_customer_sk
        ) AS store_purchase_count,
        IIF(c.c_birth_year IS NULL, 'Unknown', CONCAT(c.c_birth_year, '')) AS birth_year
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        items.total_sales_quantity,
        items.total_sales_amount
    FROM 
        item
    JOIN 
        item_sales_cte items ON item.i_item_sk = items.ws_item_sk
    WHERE 
        items.rank <= 10
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(ca.ca_address_sk) AS address_count,
    STRING_AGG(DISTINCT CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_zip)) AS complete_addresses,
    GROUPING(ca.ca_state) AS state_grouping,
    ci.item_id,
    ci.product_name,
    ci.total_sales_quantity,
    ci.total_sales_amount
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_analysis ca_analysis ON ca_analysis.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    top_items ci ON ca_analysis.purchase_count > 0
GROUP BY 
    ca.ca_city, ca.ca_state, ci.item_id, ci.product_name
HAVING 
    COUNT(ca.ca_address_sk) > 5
ORDER BY 
    ca.ca_state, COUNT(ca.ca_address_sk) DESC;
