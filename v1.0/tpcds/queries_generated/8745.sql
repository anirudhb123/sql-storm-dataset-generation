
WITH CustomerSummary AS (
    SELECT 
        DISTINCT c.c_customer_id,
        d.d_year,
        cd.cd_gender,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id, d.d_year, cd.cd_gender
),
IncomeBracket AS (
    SELECT 
        cd.cd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cs.c_customer_id,
    cs.d_year,
    cs.cd_gender,
    cs.total_returns,
    cs.total_return_amount,
    cs.total_web_sales,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    CustomerSummary cs
LEFT JOIN 
    IncomeBracket ib ON cs.c_customer_id = ib.cd_demo_sk
WHERE 
    cs.total_returns > 0
ORDER BY 
    cs.total_return_amount DESC, cs.total_web_sales DESC
LIMIT 100;
