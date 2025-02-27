
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single' 
        END AS marital_status,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.c_email_address,
    ss.total_sales,
    ss.order_count,
    ss.avg_profit,
    cd.marital_status,
    CASE 
        WHEN cd.ib_income_band_sk IS NULL THEN 'Unknown'
        ELSE CONCAT('Income Band: ', cd.ib_lower_bound, ' - ', cd.ib_upper_bound)
    END AS income_band
FROM 
    customer cs
LEFT JOIN SalesSummary ss ON cs.c_current_cdemo_sk = ss.web_site_id
LEFT JOIN CustomerDemographics cd ON cs.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    (ss.total_sales > (SELECT AVG(total_sales) FROM SalesSummary) OR ss.total_sales IS NULL)
    AND cd.cd_gender = 'F'
ORDER BY 
    ss.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
