
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        sm.sm_type AS shipping_mode,
        cd.cd_gender AS customer_gender,
        ib.ib_income_band_sk AS income_band
    FROM 
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ws.ws_item_sk, 
        d.d_year, 
        d.d_month_seq, 
        sm.sm_type, 
        cd.cd_gender, 
        ib.ib_income_band_sk
), RankedSales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY sales_year, income_band ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    r.sales_year,
    r.income_band,
    COUNT(r.ws_item_sk) AS item_count,
    SUM(r.total_quantity) AS total_quantity_sold,
    SUM(r.total_sales) AS total_revenue,
    SUM(r.total_tax) AS total_tax_collected,
    MAX(r.total_sales) AS max_sales,
    MIN(r.total_sales) AS min_sales,
    AVG(r.total_sales) AS avg_sales,
    LISTAGG(r.shipping_mode, ', ') WITHIN GROUP (ORDER BY r.shipping_mode) AS shipping_modes,
    LISTAGG(r.customer_gender, ', ') WITHIN GROUP (ORDER BY r.customer_gender) AS customer_genders
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
GROUP BY 
    r.sales_year, 
    r.income_band
ORDER BY 
    r.sales_year, 
    r.income_band;
