
WITH RevenueAnalysis AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_revenue,
        ws_item_sk,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS revenue_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ra.ws_item_sk,
        ra.total_revenue,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        RevenueAnalysis ra
    JOIN 
        item i ON ra.ws_item_sk = i.i_item_sk
    WHERE 
        ra.revenue_rank <= 10
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
RelevantIncomeBands AS (
    SELECT 
        DISTINCT ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        household_demographics hd 
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    tc.total_revenue,
    rs.order_count,
    CASE 
        WHEN rs.avg_order_value IS NULL THEN 'No Orders'
        WHEN rs.avg_order_value < 50 THEN 'Low Value'
        WHEN rs.avg_order_value BETWEEN 50 AND 150 THEN 'Medium Value'
        ELSE 'High Value'
    END AS customer_value_category,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    CustomerStatistics rs
JOIN 
    TopItems tc ON rs.order_count > 0 AND tc.ws_item_sk IN (
        SELECT ws_item_sk
        FROM web_sales
        WHERE ws_bill_customer_sk = rs.c_customer_sk
    )
LEFT JOIN 
    RelevantIncomeBands ib ON rs.cd_income_band_sk = ib.ib_income_band_sk
WHERE 
    rs.cd_gender = 'F' 
    AND EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_item_sk = tc.ws_item_sk 
        AND ss.ss_sale_date BETWEEN '2022-01-01' AND '2022-12-31'
        HAVING SUM(ss.ss_sales_price) > 500
        GROUP BY ss.ss_item_sk
    )
ORDER BY 
    total_revenue DESC;
