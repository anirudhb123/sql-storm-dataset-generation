
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
),
StoreSalesSummary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        AVG(ss_quantity) AS avg_quantity_sold
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 0
            ELSE cd.cd_dep_count 
        END AS dependents_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemSalesData AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_sold,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
)
SELECT 
    s.s_store_sk,
    SUM(s.total_net_profit) AS store_net_profit,
    AVG(s.avg_quantity_sold) AS average_quantity,
    c.cd_gender,
    c.cd_marital_status,
    COUNT(DISTINCT cs.c_customer_sk) AS customer_count
FROM 
    StoreSalesSummary s
JOIN 
    CustomerDemographics c ON s.ss_store_sk = c.c_customer_sk -- Assuming ss_store_sk represents customer
LEFT JOIN 
    ItemSalesData i ON s.ss_store_sk = i.i_item_sk
WHERE 
    c.cd_marital_status = 'M'
GROUP BY 
    s.s_store_sk, c.cd_gender, c.cd_marital_status
HAVING 
    SUM(s.total_net_profit) > 1000
ORDER BY 
    store_net_profit DESC
LIMIT 10;
