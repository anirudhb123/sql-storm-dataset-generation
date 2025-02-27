
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr.ticket_number) AS total_store_returns,
        COUNT(DISTINCT wr.order_number) AS total_web_returns,
        SUM(sr.return_amt) AS total_store_return_amount,
        SUM(wr.return_amt) AS total_web_return_amount,
        SUM(COALESCE(sr.return_quantity, 0)) AS total_store_return_quantity,
        SUM(COALESCE(wr.return_quantity, 0)) AS total_web_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
),
PromotionalImpact AS (
    SELECT 
        ws.ws_web_site_sk,
        AVG(ws.net_profit) AS avg_net_profit,
        SUM(ws.ext_sales_price) AS total_sales_price,
        COUNT(DISTINCT p.p_promo_id) AS promos_count
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        ws.ws_web_site_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cd.cd_gender, 'U') AS gender,
        cd.cd_marital_status,
        dd.d_year,
        ib.ib_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        date_dim dd ON c.c_birth_year = dd.d_year
)
SELECT 
    cd.c_customer_id,
    cd.gender,
    cd.cd_marital_status,
    cd.d_year,
    COALESCE(cs.total_store_returns, 0) AS store_return_count,
    COALESCE(cs.total_web_returns, 0) AS web_return_count,
    COALESCE(cs.total_store_return_amount, 0) AS total_store_return_amount,
    COALESCE(cs.total_web_return_amount, 0) AS total_web_return_amount,
    pi.avg_net_profit,
    pi.total_sales_price,
    pi.promos_count
FROM 
    CustomerDetails cd
LEFT JOIN 
    CustomerReturnStats cs ON cd.c_customer_id = cs.c_customer_id
LEFT JOIN 
    PromotionalImpact pi ON cd.c_customer_id = pi.ws_web_site_sk
WHERE 
    cd.gender != 'U' AND 
    (cd.cd_marital_status IS NULL OR cd.cd_marital_status != 'S')
ORDER BY 
    total_store_return_amount DESC
LIMIT 100;
