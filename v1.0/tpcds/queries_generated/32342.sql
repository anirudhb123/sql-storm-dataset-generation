
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_order_number) AS order_level
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) 
        AND ws.ws_sold_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023 AND d.d_month_seq = 10)
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
),
ProfitSummary AS (
    SELECT 
        c.c_customer_sk,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sales_price IS NOT NULL
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    cd.cd_gender,
    COALESCE(income_ib.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(income_ib.ib_upper_bound, 0) AS income_upper_bound,
    s.total_sales,
    s.avg_quantity,
    p.order_level,
    CASE 
        WHEN s.total_sales > 10000 THEN 'High'
        WHEN s.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low' 
    END AS sales_category
FROM 
    CustomerData c
LEFT JOIN 
    ProfitSummary s ON c.c_customer_sk = s.c_customer_sk
LEFT JOIN 
    income_band income_ib ON c.hd_income_band_sk = income_ib.ib_income_band_sk
LEFT JOIN 
    SalesData p ON s.sales_rank = p.order_level
WHERE 
    c.total_profit > 1000
    AND c.cd_gender IS NOT NULL
ORDER BY 
    s.total_sales DESC, customer_name;
