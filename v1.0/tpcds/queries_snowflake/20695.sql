
WITH RECURSIVE income_distribution AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        1 AS level,
        CAST(NULL AS STRING) AS aggregated_names
    FROM income_band
    UNION ALL
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        id.level + 1,
        CONCAT(id.aggregated_names, 
               CASE 
                    WHEN id.aggregated_names IS NOT NULL THEN ', ' 
                    ELSE '' 
               END, 
               ib.ib_income_band_sk) 
    FROM income_band ib
    INNER JOIN income_distribution id ON id.ib_income_band_sk < ib.ib_income_band_sk
    WHERE id.level < 3
),
store_sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        AVG(ss_net_profit) AS avg_profit
    FROM store_sales
    GROUP BY ss_store_sk
),
return_summary AS (
    SELECT 
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_store_sk
),
sales_return_combined AS (
    SELECT 
        s.ss_store_sk,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales
    FROM store_sales_summary s
    LEFT JOIN return_summary r ON s.ss_store_sk = r.sr_store_sk
),
final_report AS (
    SELECT 
        ss.ss_store_sk,
        ss.total_sales,
        ss.total_returns,
        ss.total_return_amount,
        ss.net_sales,
        CASE 
            WHEN ss.total_sales = 0 THEN NULL
            ELSE ROUND((COALESCE(ss.total_returns, 0)::DECIMAL / NULLIF(ss.total_sales, 0)) * 100, 2) 
        END AS return_percentage,
        (
            SELECT 
                LISTAGG(CONCAT(c.c_first_name, ' ', c.c_last_name), '; ') WITHIN GROUP (ORDER BY c.c_first_name, c.c_last_name)
            FROM customer c 
            INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
            WHERE cd.cd_marital_status = 'M'
              AND c.c_customer_sk IN (
                  SELECT DISTINCT ws_ship_customer_sk 
                  FROM web_sales 
                  WHERE ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
              )
        ) AS married_customers_names
    FROM sales_return_combined ss
)
SELECT 
    fs.ss_store_sk,
    fs.total_sales,
    fs.total_returns,
    fs.total_return_amount,
    fs.net_sales,
    fs.return_percentage,
    id.aggregated_names AS income_band_details 
FROM final_report fs
LEFT JOIN income_distribution id ON (fs.total_sales BETWEEN id.ib_lower_bound AND id.ib_upper_bound)
WHERE fs.net_sales > 0
ORDER BY fs.net_sales DESC;
