
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        d.d_year AS sales_year
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year >= 2020
    GROUP BY
        c.c_customer_id, d.d_year
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        customer_demographics cd
    JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), CustomerPerformance AS (
    SELECT 
        ss.c_customer_id,
        ss.total_profit,
        ss.order_count,
        ss.avg_order_value,
        CASE
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        FLOOR((ss.total_profit / NULLIF(ss.order_count, 0)) * 100) AS profit_per_order_percentage,
        CONCAT(cd.ib_lower_bound, ' - ', cd.ib_upper_bound) AS income_band
    FROM
        SalesSummary ss
    JOIN
        CustomerDemographics cd ON ss.c_customer_id = cd.cd_demo_sk
)
SELECT 
    gender,
    cd_marital_status,
    AVG(total_profit) AS avg_profit,
    AVG(order_count) AS avg_orders,
    AVG(avg_order_value) AS avg_order_value,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    income_band
FROM
    CustomerPerformance
GROUP BY 
    gender, cd_marital_status, income_band
ORDER BY 
    avg_profit DESC, customer_count DESC;
