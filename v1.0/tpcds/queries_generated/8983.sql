
WITH SalesData AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_net_profit,
        d_year,
        c_gender,
        ib_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        d_year, c_gender, ib_income_band_sk
),
AggregatedData AS (
    SELECT 
        d_year,
        c_gender,
        ib_income_band_sk,
        total_sales,
        total_orders,
        avg_net_profit,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    d_year,
    c_gender,
    ib_income_band_sk,
    total_sales,
    total_orders,
    avg_net_profit,
    sales_rank
FROM 
    AggregatedData
WHERE 
    sales_rank <= 5 AND (ib_income_band_sk BETWEEN 1 AND 3)
ORDER BY 
    d_year, total_sales DESC;
