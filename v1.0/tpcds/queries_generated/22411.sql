
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
CustomerAvgSpending AS (
    SELECT 
        c.c_customer_sk,
        AVG(ws_net_paid) as avg_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
CustomerCategory AS (
    SELECT 
        cd.cd_gender,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating 
        END AS credit_category,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, credit_category
),
HighValueItems AS (
    SELECT 
        ir.i_item_sk,
        SUM(ws.net_profit) AS total_profit
    FROM 
        item ir
    JOIN 
        web_sales ws ON ir.i_item_sk = ws.ws_item_sk
    GROUP BY 
        ir.i_item_sk
    HAVING 
        SUM(ws.net_profit) > 10000
)
SELECT 
    c.customer_count,
    cc.cd_gender,
    cc.credit_category,
    r.rs_item_sk,
    r.ws_sales_price,
    COALESCE(hvi.total_profit, 0) AS item_profit,
    (SELECT COUNT(*) FROM store_sales WHERE ss_item_sk = r.ws_item_sk) AS store_sales_count
FROM 
    CustomerAvgSpending c
JOIN 
    CustomerCategory cc ON c.c_customer_sk = cc.c_customer_sk
LEFT JOIN 
    RankedSales r ON r.rn = 1
LEFT JOIN 
    HighValueItems hvi ON r.ws_item_sk = hvi.i_item_sk
WHERE 
    (cc.cd_gender = 'F' OR cc.cd_gender IS NULL)
    AND r.ws_sales_price > 50
    AND COALESCE(item_profit, 0) > AVG(NULLIF(ws_sales_price, 0) OVER()) -- unusual avg with null safety
ORDER BY 
    item_profit DESC
FETCH FIRST 100 ROWS ONLY;
