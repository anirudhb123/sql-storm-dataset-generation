
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit,
        RANK() OVER (ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                               (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
IncomeBandSummary AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(ss_net_paid) AS total_income
    FROM 
        store_sales 
    JOIN 
        household_demographics hd ON ss_customer_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    cd.c_customer_id,
    cs.total_net_paid,
    cs.order_count,
    cs.avg_net_profit,
    ibs.total_income,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    SalesSummary cs
JOIN 
    CustomerDetails cd ON cs.ws_bill_customer_sk = cd.c_customer_id
LEFT JOIN 
    IncomeBandSummary ibs ON cd.cd_income_band_sk = ibs.ib_income_band_sk
WHERE 
    cs.sales_rank <= 100
ORDER BY 
    cs.total_net_paid DESC;
