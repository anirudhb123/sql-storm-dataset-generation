
WITH SalesData AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit,
        DATE(d_date) AS sale_date,
        c_gender,
        c_marital_status,
        c_education_status,
        ib_income_band_sk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2023
    GROUP BY sale_date, c_gender, c_marital_status, c_education_status, ib_income_band_sk
),
RankedSales AS (
    SELECT 
        sale_date,
        c_gender,
        c_marital_status,
        c_education_status,
        ib_income_band_sk,
        total_sales,
        order_count,
        avg_net_profit,
        RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData
)
SELECT 
    sale_date,
    c_gender,
    c_marital_status,
    c_education_status,
    ib_income_band_sk,
    total_sales,
    order_count,
    avg_net_profit
FROM RankedSales
WHERE sales_rank <= 5
ORDER BY ib_income_band_sk, total_sales DESC;
