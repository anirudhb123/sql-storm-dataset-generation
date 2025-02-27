
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT sr.ticket_number) AS return_count,
        SUM(sr.return_amt) AS total_return_amt,
        SUM(ws.net_paid) AS total_sales_amt
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
IncomeBandStats AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(cs.cs_item_sk) AS sales_count,
        SUM(cs.cs_net_profit) AS total_income
    FROM 
        catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_cdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
),
FinalStats AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        cs.return_count,
        cs.total_return_amt,
        ibs.sales_count,
        ibs.total_income
    FROM 
        CustomerStats cs
    LEFT JOIN IncomeBandStats ibs ON cs.c_customer_sk = (SELECT MAX(c.c_customer_sk) FROM customer c WHERE c.c_birth_month = 5)
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.cd_purchase_estimate,
    fs.return_count,
    fs.total_return_amt,
    fs.sales_count,
    fs.total_income
FROM 
    FinalStats fs
WHERE 
    fs.total_return_amt > 100
ORDER BY 
    fs.total_income DESC, fs.return_count DESC;
