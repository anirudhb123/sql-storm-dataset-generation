
WITH SalesData AS (
    SELECT 
        DATE(DATEADD(DAY, d.d_dom - 1, '2001-01-01')) AS sale_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        DATE(DATEADD(DAY, d.d_dom - 1, '2001-01-01')), 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ib.ib_lower_bound, 
        ib.ib_upper_bound
),
AggregatedData AS (
    SELECT 
        sale_date,
        cd_gender,
        cd_marital_status,
        COUNT(*) AS sales_count,
        AVG(total_quantity) AS avg_quantity_per_sale,
        SUM(total_profit) AS total_profit
    FROM 
        SalesData
    GROUP BY 
        sale_date, 
        cd_gender, 
        cd_marital_status
)
SELECT 
    sale_date,
    cd_gender,
    cd_marital_status,
    sales_count,
    avg_quantity_per_sale,
    total_profit,
    CASE 
        WHEN total_profit > 100000 THEN 'High Profit'
        WHEN total_profit BETWEEN 50000 AND 100000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    AggregatedData
ORDER BY 
    sale_date ASC, 
    total_profit DESC;
