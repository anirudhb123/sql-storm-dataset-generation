
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_net_profit,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
), 
CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_age_group,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_age_group
), 
SalesAnalysis AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        SUM(s.ws_net_profit) AS total_net_profit,
        SUM(s.ws_quantity) AS total_quantity,
        AVG(s.ws_sales_price) AS average_sales_price
    FROM 
        SalesCTE s
    JOIN 
        item ON s.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    sa.i_item_desc,
    sa.total_net_profit,
    sa.total_quantity,
    sa.average_sales_price
FROM 
    CustomerCTE c
JOIN 
    SalesAnalysis sa ON c.order_count > 5
WHERE 
    c.cd_gender IS NOT NULL
ORDER BY 
    sa.total_net_profit DESC
LIMIT 10;
