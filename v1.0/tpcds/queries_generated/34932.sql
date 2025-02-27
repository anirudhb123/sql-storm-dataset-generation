
WITH RECURSIVE MonthlyReturnStats AS (
    SELECT
        EXTRACT(YEAR FROM d_date) AS year,
        EXTRACT(MONTH FROM d_date) AS month,
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM
        web_returns
    JOIN date_dim ON wr_returned_date_sk = d_date_sk
    GROUP BY
        EXTRACT(YEAR FROM d_date),
        EXTRACT(MONTH FROM d_date)
    
    UNION ALL
    
    SELECT
        year,
        month + 1,
        total_web_returns,
        total_return_amount
    FROM
        MonthlyReturnStats
    WHERE
        month < 12
),
CustomerEducation AS (
    SELECT
        cd_demo_sk,
        cd_education_status,
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM
        customer_demographics
    JOIN customer ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        cd_demo_sk, cd_education_status, cd_gender
),
SalesData AS (
    SELECT
        ws_sales_price,
        ws_net_profit,
        EXTRACT(MONTH FROM d_date) AS sales_month,
        AVG(ws_net_profit) OVER (PARTITION BY EXTRACT(MONTH FROM d_date)) AS avg_monthly_profit,
        CASE
            WHEN ws_sales_price IS NULL THEN 'Unknown Price'
            ELSE ws_sales_price::varchar
        END AS sales_category
    FROM
        web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
)
SELECT
    ed.cd_education_status,
    ed.cd_gender,
    SUM(CASE WHEN wr.return_month IS NOT NULL THEN wr.total_web_returns ELSE 0 END) AS total_returns,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    AVG(sd.avg_monthly_profit) AS average_profit,
    SUM(sd.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT sd.ws_sales_price) FILTER (WHERE sd.sales_category = 'Unknown Price') AS unknown_price_count
FROM
    CustomerEducation ed
LEFT JOIN (
    SELECT
        m.year,
        m.month AS return_month,
        m.total_web_returns
    FROM
        MonthlyReturnStats m
) AS wr ON EXTRACT(MONTH FROM CURRENT_DATE) = wr.return_month
JOIN customer c ON c.c_current_cdemo_sk = ed.cd_demo_sk
JOIN SalesData sd ON sd.sales_month = EXTRACT(MONTH FROM CURRENT_DATE)
WHERE
    (cd_gender IS NOT NULL OR cd_gender = 'F')
    AND (cd_education_status IS NOT NULL AND (cd_education_status LIKE '%graduate%' OR cd_education_status LIKE '%postgraduate%'))
GROUP BY
    ed.cd_education_status,
    ed.cd_gender
ORDER BY
    total_net_profit DESC;
