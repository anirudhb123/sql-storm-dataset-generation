
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        DATE(DATEADD(DAY, -30, CURRENT_DATE)) AS report_period_start,
        CURRENT_DATE AS report_period_end
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date >= DATEADD(DAY, -30, CURRENT_DATE))
        AND ws.ws_sold_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date <= CURRENT_DATE)
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
),
PerformanceSummary AS (
    SELECT 
        COUNT(1) AS num_customers,
        SUM(total_sales) AS total_sales_summary,
        AVG(total_orders) AS average_orders_per_customer,
        AVG(average_profit) AS average_profit_per_customer,
        report_period_start,
        report_period_end
    FROM 
        CustomerSales
)

SELECT 
    ps.num_customers,
    ps.total_sales_summary,
    ps.average_orders_per_customer,
    ps.average_profit_per_customer,
    ps.report_period_start,
    ps.report_period_end
FROM 
    PerformanceSummary ps
WHERE 
    ps.num_customers > 0
ORDER BY 
    ps.total_sales_summary DESC
LIMIT 10;
