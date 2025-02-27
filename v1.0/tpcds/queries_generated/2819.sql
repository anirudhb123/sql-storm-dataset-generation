
WITH CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.order_number) AS total_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
SalesStats AS (
    SELECT
        w.web_site_id,
        SUM(ws.net_paid) AS total_sales,
        AVG(ws.net_profit) AS avg_net_profit,
        COUNT(ws.order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.web_site_sk = w.web_site_sk
    WHERE 
        ws.sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        w.web_site_id
),
IncomeBands AS (
    SELECT 
        ib.income_band_sk,
        ib.lower_bound,
        ib.upper_bound,
        COUNT(hd.hd_demo_sk) AS household_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.income_band_sk
    GROUP BY 
        ib.income_band_sk, ib.lower_bound, ib.upper_bound
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    ca.ca_city,
    ca.ca_state,
    cs.total_sales,
    cs.avg_net_profit,
    cb.total_return_amount,
    ib.lower_bound,
    ib.upper_bound,
    ib.household_count
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    CustomerReturns cb ON c.c_customer_sk = cb.returning_customer_sk
LEFT JOIN 
    SalesStats cs ON cs.web_site_id IN (SELECT web_site_id FROM web_site WHERE web_company_id = c.c_current_cdemo_sk)
LEFT JOIN 
    IncomeBands ib ON (c.c_current_cdemo_sk IS NOT NULL AND c.c_current_cdemo_sk BETWEEN ib.lower_bound AND ib.upper_bound)
WHERE 
    (cb.total_returns IS NULL OR cb.total_return_amount > 100)
    AND (cs.total_orders > 5 OR cs.total_sales IS NULL)
ORDER BY 
    cs.total_sales DESC, 
    cb.total_return_amount ASC;
