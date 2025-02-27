
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS row_num
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating, ca.ca_state
),
MaxProfit AS (
    SELECT 
        MAX(total_net_profit) AS max_profit
    FROM 
        CustomerInfo
    WHERE 
        cd_gender = 'F'
),
FilteredSales AS (
    SELECT 
        c.c_customer_id,
        si.ws_item_sk,
        si.ws_quantity,
        si.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY si.ws_item_sk ORDER BY si.ws_net_profit DESC) AS rank
    FROM 
        SalesCTE si
    INNER JOIN 
        CustomerInfo c ON si.ws_order_number IN (SELECT ws_order_number FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
    WHERE 
        c.total_net_profit > (SELECT max_profit FROM MaxProfit)
)

SELECT 
    c.c_customer_id,
    si.ws_item_sk,
    si.ws_quantity,
    si.ws_net_profit,
    CASE 
        WHEN si.ws_net_profit IS NULL THEN 'No Profit' 
        ELSE CONCAT('Profit: ', CAST(si.ws_net_profit AS VARCHAR(10))) 
    END AS profit_statement
FROM 
    FilteredSales si
INNER JOIN 
    customer c ON si.c_customer_id = c.c_customer_id
WHERE 
    si.rank <= 5
ORDER BY 
    c.c_customer_id, si.ws_net_profit DESC;
