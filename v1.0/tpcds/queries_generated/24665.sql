
WITH RECURSIVE CustomerCTE AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 1 AS Level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.customer_sk, c.c_first_name, c.c_last_name, cte.Level + 1
    FROM customer c
    JOIN CustomerCTE cte ON c.c_current_cdemo_sk = cte.c_customer_sk
), 
IncomeData AS (
    SELECT 
        h.hd_demo_sk,
        CASE
            WHEN h.hd_income_band_sk IS NULL THEN 'Unknown'
            ELSE CONCAT('Income Band: ', h.hd_income_band_sk)
        END AS Income_Band,
        COUNT(DISTINCT c.c_customer_id) AS Customer_Count
    FROM household_demographics h
    LEFT JOIN customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    WHERE h.hd_buy_potential IS NOT NULL
    GROUP BY h.hd_demo_sk, h.hd_income_band_sk
), 
SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS Total_Quantity, 
        SUM(ws.ws_net_profit) AS Total_Profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d) 
                                    AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY ws.ws_item_sk
), 
StoreSalesSummary AS (
    SELECT
        ss.ss_store_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS Total_Transactions,
        SUM(ss.ss_net_paid) AS Total_Sales
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year > 2020)
    GROUP BY ss.ss_store_sk
)

SELECT 
    cs.c_first_name,
    cs.c_last_name,
    id.Income_Band,
    COALESCE(sss.Total_Transactions, 0) AS Store_Transaction_Count,
    COALESCE(sss.Total_Sales, 0) AS Store_Transaction_Sales,
    COALESCE(sd.Total_Quantity, 0) AS Web_Item_Quantity_Sold,
    COALESCE(sd.Total_Profit, 0) AS Web_Item_Profit,
    COUNT(DISTINCT cs.c_customer_sk) OVER (PARTITION BY cs.c_current_cdemo_sk) AS Cohort_Size
FROM CustomerCTE cs 
LEFT JOIN IncomeData id ON id.hd_demo_sk = cs.c_current_hdemo_sk
LEFT JOIN SalesData sd ON sd.ws_item_sk = (
    SELECT i.i_item_sk
    FROM item i 
    ORDER BY RANDOM() 
    LIMIT 1
)
LEFT JOIN StoreSalesSummary sss ON sss.ss_store_sk = cs.c_current_addr_sk
WHERE 
    (id.Customer_Count > 1 OR id.Customer_Count IS NULL)
    AND (cs.c_birth_year IS NOT NULL OR cs.c_birth_month IS NOT NULL)
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr 
        WHERE cr.cr_returning_customer_sk = cs.c_customer_sk
        AND cr.cr_return_quantity > 0
    )
ORDER BY cs.c_last_name, cs.c_first_name;
