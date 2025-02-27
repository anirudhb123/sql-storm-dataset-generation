
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
income_stats AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        SUM(cs.total_orders) AS total_orders,
        SUM(cs.total_profit) AS total_profit,
        AVG(cs.avg_order_value) AS avg_order_value
    FROM 
        customer_stats cs
    JOIN 
        household_demographics hd ON cs.c_current_cdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
),
sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_transactions,
        AVG(ws.ws_net_paid_inc_tax) AS avg_sale_per_transaction
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)

SELECT 
    ib.ib_income_band_sk,
    isr.customer_count,
    isr.total_orders,
    isr.total_profit,
    isr.avg_order_value,
    ss.d_year,
    ss.total_sales,
    ss.total_transactions,
    ss.avg_sale_per_transaction
FROM 
    income_stats isr
JOIN 
    sales_summary ss ON ss.total_transactions > 0
LEFT JOIN 
    income_band ib ON isr.ib_income_band_sk = ib.ib_income_band_sk
WHERE 
    isr.total_profit IS NOT NULL 
ORDER BY 
    isr.total_profit DESC, ss.total_sales DESC;
