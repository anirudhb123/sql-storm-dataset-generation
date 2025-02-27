
WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        COUNT(DISTINCT ws.ws_ship_mode_sk) AS distinct_shipping_modes
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq IN (1, 2, 3)  -- First quarter
    GROUP BY 
        c.c_customer_id
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics AS cd
    LEFT JOIN 
        household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    sd.c_customer_id,
    sd.total_sales_quantity,
    sd.total_net_profit,
    sd.total_orders,
    sd.avg_order_value,
    sd.distinct_shipping_modes,
    d.cd_gender,
    d.cd_marital_status,
    d.ib_lower_bound,
    d.ib_upper_bound
FROM 
    SalesData AS sd
JOIN 
    Demographics AS d ON sd.c_customer_id = SUBSTRING(d.cd_demo_sk, 1, 16)    -- Example logic for joining based on customer_id
ORDER BY 
    sd.total_net_profit DESC
LIMIT 100;
