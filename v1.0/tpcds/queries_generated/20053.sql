
WITH RECURSIVE CustomerRank AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
), 

SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    LEFT JOIN 
        customer_rank cr ON ws.ws_bill_customer_sk = cr.c_customer_sk
    GROUP BY 
        ws.ws_item_sk
),

UnreturnedSales AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_sold,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        store_sales ss
    LEFT OUTER JOIN 
        store_returns sr ON ss.ss_item_sk = sr.sr_item_sk AND sr.sr_returned_date_sk IS NULL
    WHERE 
        sr.sr_item_sk IS NULL
    GROUP BY 
        ss.ss_item_sk
)

SELECT 
    ca.ca_city, 
    ca.ca_state, 
    cr.c_first_name, 
    cr.c_last_name, 
    COALESCE(sd.total_quantity, 0) AS online_sales_quantity,
    COALESCE(us.total_sold, 0) AS store_sales_quantity,
    (COALESCE(sd.total_net_profit, 0) - COALESCE(us.total_net_profit, 0)) AS net_profit_difference
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    CustomerRank cr ON c.c_customer_sk = cr.c_customer_sk AND cr.rank <= 5
LEFT JOIN 
    SalesData sd ON sd.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand='Acme')
LEFT JOIN 
    UnreturnedSales us ON us.ss_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand='Acme')
WHERE 
    ca.ca_city IS NOT NULL OR ca.ca_state IS NOT NULL
ORDER BY 
    net_profit_difference DESC
LIMIT 50
OFFSET (SELECT COUNT(*) FROM customer_rank WHERE rank <= 5) / 2;
