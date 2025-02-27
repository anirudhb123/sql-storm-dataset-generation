
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
    UNION ALL
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ch.rn + 1
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer c ON ch.c_customer_sk = c.c_current_cdemo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ch.rn < 4
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(i.i_current_price, 0) * 1.1 AS adjusted_price
    FROM 
        item i
    WHERE 
        i.i_current_price IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        SUM(ws.ws_net_profit) > 0
),
FinalResults AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        id.i_item_id,
        sd.total_sales_quantity,
        sd.total_profit,
        CASE 
            WHEN sd.total_sales_quantity IS NULL THEN 'No Sales'
            ELSE 'Sales Exists'
        END AS sales_status
    FROM 
        CustomerHierarchy ch
    FULL OUTER JOIN 
        ItemDetails id ON id.i_item_sk = ch.c_customer_sk
    LEFT JOIN 
        SalesData sd ON sd.ws_item_sk = id.i_item_sk AND sd.sales_rank = 1
    WHERE 
        ch.rn = 1 OR id.invalidated IS NULL
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.i_item_id,
    f.total_sales_quantity,
    f.total_profit,
    f.sales_status,
    CASE 
        WHEN f.total_profit < 0 THEN 'Loss' 
        WHEN f.total_profit > 0 THEN 'Profit' 
        ELSE 'Break Even' 
    END AS profit_status
FROM 
    FinalResults f
WHERE 
    f.sales_status = 'Sales Exists'
ORDER BY 
    f.total_profit DESC NULLS LAST;
