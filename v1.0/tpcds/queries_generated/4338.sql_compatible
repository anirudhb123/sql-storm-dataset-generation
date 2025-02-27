
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rnk
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023 AND
        (cd.cd_gender IS NULL OR cd.cd_marital_status = 'M')
),
aggregated_sales AS (
    SELECT 
        year,
        month,
        COUNT(DISTINCT ws_item_sk) AS total_items,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_sales_price) AS average_price
    FROM (
        SELECT 
            d_year AS year,
            d_month_seq AS month,
            ws_item_sk,
            ws_quantity,
            ws_sales_price,
            ws_net_paid,
            ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rnk
        FROM 
            sales_data
        WHERE 
            rnk = 1
    ) AS latest_sales
    GROUP BY 
        year, month
)
SELECT 
    ag.year,
    ag.month,
    ag.total_items,
    ag.total_quantity,
    ag.total_net_paid,
    ag.average_price,
    COALESCE(ib.ib_income_band_sk, 0) AS income_band
FROM 
    aggregated_sales ag
LEFT JOIN 
    household_demographics hd ON hd.hd_demo_sk IN (
        SELECT cd.cd_demo_sk
        FROM customer_demographics cd
        WHERE cd.cd_income_band_sk IS NOT NULL
    )
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    ag.year, ag.month;
