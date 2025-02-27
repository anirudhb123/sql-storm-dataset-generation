
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM customer c 
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
RetailAnalysis AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_transactions,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count
    FROM CustomerSales cs
    JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
),
SalesTrends AS (
    SELECT 
        ra.c_customer_id,
        ra.total_sales,
        ra.total_transactions,
        ra.cd_gender,
        ra.cd_marital_status,
        ra.cd_income_band_sk,
        ra.hd_buy_potential,
        ra.hd_dep_count,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        MAX(ws.ws_net_profit) AS max_web_profit
    FROM RetailAnalysis ra
    LEFT JOIN web_sales ws ON ra.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY 
        ra.c_customer_id,
        ra.total_sales,
        ra.total_transactions,
        ra.cd_gender,
        ra.cd_marital_status,
        ra.cd_income_band_sk,
        ra.hd_buy_potential,
        ra.hd_dep_count
),
FinalReport AS (
    SELECT 
        st.c_customer_id,
        st.total_sales,
        st.total_transactions,
        st.web_sales,
        st.max_web_profit,
        CASE 
            WHEN st.total_transactions > 10 THEN 'Frequent'
            WHEN st.total_transactions BETWEEN 5 AND 10 THEN 'Occasional'
            ELSE 'Rare'
        END AS customer_category
    FROM SalesTrends st
)
SELECT 
    fr.c_customer_id,
    fr.total_sales,
    fr.total_transactions,
    fr.web_sales,
    fr.max_web_profit,
    fr.customer_category,
    SUM(sd.ss_net_profit) AS store_sales_profit
FROM FinalReport fr
LEFT JOIN store_sales sd ON fr.c_customer_id = sd.ss_customer_sk
GROUP BY 
    fr.c_customer_id,
    fr.total_sales,
    fr.total_transactions,
    fr.web_sales,
    fr.max_web_profit,
    fr.customer_category
ORDER BY 
    fr.total_sales DESC;
