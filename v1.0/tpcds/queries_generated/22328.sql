
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        s.ss_store_sk,
        SUM(ss.ss_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_quantity) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        c.c_customer_id, s.ss_store_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cb.count AS count_customers
    FROM 
        customer_demographics cd
    JOIN (
        SELECT 
            cd_gender, 
            cd_marital_status, 
            COUNT(*) AS count
        FROM 
            customer c
        JOIN 
            customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        GROUP BY 
            cd_gender, cd_marital_status
    ) AS cb ON cd.cd_gender = cb.cd_gender AND cd.cd_marital_status = cb.cd_marital_status
),
SalesWithReasons AS (
    SELECT 
        wr.wr_order_number,
        AVG(wr.wr_return_amt_inc_tax) AS average_return_amount,
        CASE 
            WHEN wr.wr_reason_sk IS NOT NULL THEN r.r_reason_desc
            ELSE 'No Reason Given'
        END AS return_reason
    FROM 
        web_returns wr
    LEFT JOIN 
        reason r ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY 
        wr.wr_order_number, wr.wr_reason_sk
),
IncomeBandSales AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(ws.ws_ext_sales_price) AS total_income
    FROM 
        web_sales ws
    JOIN 
        household_demographics hd ON ws.ws_bill_cdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    cr.c_customer_id,
    SUM(r.total_sales) AS total_sales_by_customer,
    cdem.cd_gender,
    cdem.cd_marital_status,
    COALESCE(i.total_income, 0) AS income_by_band,
    sr.average_return_amount,
    sr.return_reason
FROM 
    RankedSales r
JOIN 
    customer c ON r.c_customer_id = c.c_customer_id
JOIN 
    CustomerDemographics cdem ON cdem.cd_gender = (SELECT cd_gender FROM customer_demographics WHERE cd_demo_sk = c.c_current_cdemo_sk)
LEFT JOIN 
    IncomeBandSales i ON i.ib_income_band_sk = (SELECT hd_income_band_sk FROM household_demographics WHERE hd_demo_sk = c.c_current_hdemo_sk)
LEFT JOIN 
    SalesWithReasons sr ON sr.wr_order_number = (SELECT MAX(wr_order_number) FROM web_returns WHERE wr_returning_customer_sk = c.c_customer_sk)
WHERE 
    r.sales_rank = 1 AND 
    (r.total_sales IS NOT NULL OR r.total_sales > 0) 
GROUP BY 
    cr.c_customer_id, cdem.cd_gender, cdem.cd_marital_status, i.total_income, sr.average_return_amount, sr.return_reason
HAVING 
    COUNT(DISTINCT r.ss_store_sk) > 2
ORDER BY 
    total_sales_by_customer DESC, income_by_band ASC;
