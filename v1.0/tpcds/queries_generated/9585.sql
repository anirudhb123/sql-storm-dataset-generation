
WITH daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_sales) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        d.d_date
),
sales_by_gender AS (
    SELECT 
        cd.cd_gender,
        SUM(ds.total_sales) AS sales_amount,
        AVG(ds.average_profit) AS avg_profit_per_day
    FROM 
        daily_sales ds
    JOIN 
        customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
sales_by_income_band AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(ds.total_sales) AS income_sales,
        COUNT(ds.order_count) AS total_orders
    FROM 
        daily_sales ds
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    sbg.cd_gender,
    ddi.ib_lower_bound,
    ddi.ib_upper_bound,
    sbg.sales_amount,
    sbi.income_sales,
    sbi.total_orders,
    sbg.avg_profit_per_day
FROM 
    sales_by_gender sbg
JOIN 
    sales_by_income_band sbi ON sbg.cd_gender = sbi.cd_gender
JOIN 
    income_band ib ON sbi.ib_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    sbg.sales_amount DESC;
