
WITH ItemSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc,
        is.total_quantity_sold,
        is.total_net_profit
    FROM ItemSales is
    JOIN item i ON is.ws_item_sk = i.i_item_sk
    WHERE is.item_rank <= 10
),
HighIncomeDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        ib.ib_lower_bound, 
        ib.ib_upper_bound
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 100000
),
SalesByDemographics AS (
    SELECT 
        t.customer_id, 
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        SUM(s.ss_net_profit) AS total_profit
    FROM store_sales s
    JOIN customer t ON s.ss_customer_sk = t.c_customer_sk
    JOIN HighIncomeDemographics d ON t.c_current_cdemo_sk = d.cd_demo_sk
    GROUP BY t.customer_id
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    si.total_sales,
    si.total_profit,
    CASE 
        WHEN si.total_sales > 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS sales_category
FROM TopItems ti
LEFT JOIN SalesByDemographics si ON ti.i_item_id = si.customer_id
ORDER BY ti.total_net_profit DESC, si.total_sales DESC;
