
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY c.c_birth_year DESC) AS marital_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    WHERE 
        hd.hd_vehicle_count > 0
), order_reasons AS (
    SELECT 
        wr.refunded_customer_sk,
        COUNT(*) AS total_web_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk BETWEEN 1 AND 10
    GROUP BY 
        wr.refunded_customer_sk
)
SELECT 
    c_info.c_first_name,
    c_info.c_last_name,
    cs.total_sales,
    cs.total_orders,
    COALESCE(ors.total_web_returns, 0) AS total_returns,
    COALESCE(ors.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN cs.sales_rank = 1 THEN 'Top Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM 
    customer_info c_info
LEFT JOIN 
    sales_summary cs ON c_info.c_customer_sk = cs.web_site_sk
LEFT JOIN 
    order_reasons ors ON c_info.c_customer_sk = ors.refunded_customer_sk
WHERE 
    c_info.marital_rank <= 5
    AND (c_info.hd_income_band_sk IS NOT NULL OR c_info.hd_buy_potential LIKE 'High%')
ORDER BY 
    cs.total_sales DESC;
