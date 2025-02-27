
WITH RECURSIVE sales_totals AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_paid_inc_tax) AS total_sales,
        COUNT(ss_item_sk) AS total_items,
        CURRENT_DATE AS calculation_date
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_month_seq = (SELECT d_month_seq FROM date_dim WHERE d_date = CURRENT_DATE))
    GROUP BY 
        s_store_sk
    UNION ALL
    SELECT 
        st.s_store_sk,
        SUM(ss_net_paid_inc_tax) AS total_sales,
        COUNT(ss_item_sk) AS total_items,
        ADDDATE(calculation_date, INTERVAL -1 DAY)
    FROM 
        sales_totals st
    JOIN 
        store_sales ss ON st.s_store_sk = ss.s_store_sk 
    WHERE 
        ss_sold_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_date = ADDDATE(calculation_date, INTERVAL -1 DAY))
    GROUP BY 
        st.s_store_sk
),
average_sales AS (
    SELECT 
        s_store_sk,
        AVG(total_sales) AS avg_sales,
        AVG(total_items) AS avg_items
    FROM 
        sales_totals
    GROUP BY 
        s_store_sk
),
customer_demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_income_band_sk
)
SELECT 
    a.s_store_sk,
    a.avg_sales,
    a.avg_items,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count
FROM 
    average_sales a
JOIN 
    customer_demographics cd ON cd.cd_income_band_sk = (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound <= a.avg_sales AND ib_upper_bound > a.avg_sales)
WHERE 
    (cd.customer_count > 0 AND cd.cd_marital_status IS NOT NULL)
ORDER BY 
    a.avg_sales DESC 
LIMIT 10;
