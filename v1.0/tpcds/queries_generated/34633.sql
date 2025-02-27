
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sales_item_sk AS item_sk,
        ws_order_number,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_sales_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sales_item_sk, ws_order_number
), 
CustomerInfo AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status
), 
HighProfitItems AS (
    SELECT 
        item_sk, 
        total_profit
    FROM 
        SalesCTE
    WHERE 
        rank <= 10
)

SELECT 
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.customer_count,
    COALESCE(hpi.total_profit, 0) AS total_profit
FROM 
    CustomerInfo ci
LEFT JOIN 
    HighProfitItems hpi ON hpi.item_sk IN (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws_bill_customer_sk IN (
                SELECT 
                    c_customer_sk 
                FROM 
                    customer 
                WHERE 
                    c_last_name LIKE '%son%'
            )
    )
ORDER BY 
    ci.ca_state, 
    ci.ca_city;

UNION ALL

SELECT
    'Total' AS ca_city,
    NULL AS ca_state,
    NULL AS cd_gender,
    NULL AS cd_marital_status,
    SUM(customer_count) AS customer_count,
    SUM(COALESCE(total_profit, 0)) AS total_profit
FROM 
    CustomerInfo;
