
WITH RankedStoreSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        RANK() OVER (ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY ss_store_sk
), CustomerDetails AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_rank
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), HighValueCustomers AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent
    FROM CustomerDetails AS cd
    LEFT JOIN web_sales AS ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.gender_rank <= 10
    GROUP BY cd.c_customer_sk, cd.cd_gender, cd.cd_marital_status
), StoreInfo AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COALESCE(RSS.total_sales, 0) AS store_total_sales
    FROM store AS s
    LEFT JOIN RankedStoreSales AS RSS ON s.s_store_sk = RSS.ss_store_sk
), SalesReport AS (
    SELECT 
        st.s_store_name,
        SUM(hvc.total_spent) AS high_value_sales,
        COUNT(DISTINCT hvc.c_customer_sk) AS unique_high_value_customers
    FROM StoreInfo AS st
    LEFT JOIN HighValueCustomers AS hvc ON st.s_store_sk = hvc.cd_gender
    GROUP BY st.s_store_name
)
SELECT 
    s.s_store_name,
    s.store_total_sales,
    r.high_value_sales,
    r.unique_high_value_customers,
    CASE 
        WHEN r.high_value_sales > 100000 THEN 'High Performance'
        WHEN r.high_value_sales BETWEEN 50000 AND 100000 THEN 'Moderate Performance'
        ELSE 'Low Performance'
    END AS performance_category
FROM StoreInfo AS s
JOIN SalesReport AS r ON s.s_store_name = r.s_store_name
ORDER BY s.store_total_sales DESC, r.high_value_sales DESC;
