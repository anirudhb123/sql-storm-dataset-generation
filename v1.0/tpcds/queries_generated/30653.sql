
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_sk,
        item.i_item_desc,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_profit, 0) AS total_profit
    FROM 
        item 
    LEFT JOIN 
        (SELECT * FROM SalesData WHERE rank <= 5) sd ON item.i_item_sk = sd.ws_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        DENSE_RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
)
SELECT 
    td.c_first_name,
    td.c_last_name,
    td.cd_gender,
    td.cd_marital_status,
    SUM(ti.total_quantity) AS total_purchases,
    SUM(ti.total_profit) AS total_profit,
    COUNT(DISTINCT ti.i_item_sk) AS unique_items_purchased
FROM 
    CustomerDetails td
JOIN 
    TopItems ti ON EXISTS (
        SELECT 1 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = td.c_customer_sk AND ws.ws_item_sk = ti.i_item_sk
    )
GROUP BY 
    td.c_customer_sk, td.c_first_name, td.c_last_name, td.cd_gender, td.cd_marital_status
HAVING 
    total_profit > 0
ORDER BY 
    total_profit DESC;
