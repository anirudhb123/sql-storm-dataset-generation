
WITH RECURSIVE StoreSalesCTE AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales 
    GROUP BY 
        ss_store_sk
),
TopSales AS (
    SELECT 
        s.s_store_id,
        st.total_sales,
        st.transaction_count,
        c.cc_name AS call_center_name
    FROM 
        StoreSalesCTE st
    JOIN 
        store s ON st.ss_store_sk = s.s_store_sk
    LEFT JOIN 
        call_center c ON s.s_market_id = c.cc_mkt_id
    WHERE 
        st.sales_rank <= 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buying_behavior
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesAnalysis AS (
    SELECT 
        ts.s_store_id,
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ts.total_sales,
        ts.transaction_count,
        CASE 
            WHEN ts.total_sales > 10000 THEN 'High Value'
            WHEN ts.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        TopSales ts
    JOIN 
        web_sales ws ON ts.s_store_id = ws.ws_bill_addr_sk
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_id
)
SELECT 
    sa.s_store_id,
    COUNT(DISTINCT sa.c_customer_id) AS unique_customers,
    SUM(sa.total_sales) AS aggregated_sales,
    AVG(sa.transaction_count) AS average_transactions,
    STRING_AGG(CONCAT(sa.c_first_name, ' ', sa.c_last_name), ', ') AS customer_names,
    COUNT(CASE WHEN sa.cd_gender = 'M' THEN 1 END) AS male_customers,
    COUNT(CASE WHEN sa.cd_gender = 'F' THEN 1 END) AS female_customers
FROM 
    SalesAnalysis sa
GROUP BY 
    sa.s_store_id
HAVING 
    AVG(sa.transaction_count) > 2
ORDER BY 
    aggregated_sales DESC;
