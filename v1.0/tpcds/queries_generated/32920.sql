
WITH RECURSIVE sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_paid) DESC) AS rn
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        cs_item_sk
    HAVING 
        SUM(cs_net_paid) > 1000
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        SUM(s.rs_return_quantity) AS total_returns,
        AVG(s.rs_return_amt_inc_tax) AS avg_return_amt
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        (SELECT sr_customer_sk, sr_return_quantity, sr_return_amt_inc_tax FROM store_returns 
         UNION ALL 
         SELECT wr_returning_customer_sk, wr_return_quantity, wr_return_amt_inc_tax FROM web_returns) s 
    ON c.c_customer_sk = s.sr_customer_sk OR c.c_customer_sk = s.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_income_band_sk
),
final_report AS (
    SELECT 
        si.cs_item_sk,
        cs.total_net_paid,
        ci.c_customer_id,
        ci.cd_gender,
        ci.total_returns,
        ci.avg_return_amt
    FROM 
        sales_summary si
    JOIN 
        customer_info ci ON si.cs_item_sk = ci.cd_income_band_sk
)
SELECT 
    fr.cs_item_sk,
    fr.total_net_paid,
    fr.c_customer_id,
    fr.cd_gender,
    COALESCE(fr.total_returns, 0) AS total_returns,
    COALESCE(fr.avg_return_amt, 0.00) AS avg_return_amt,
    CASE 
        WHEN fr.total_net_paid >= 5000 THEN 'High Value'
        WHEN fr.total_net_paid >= 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM 
    final_report fr
LEFT JOIN 
    income_band ib ON fr.cd_income_band_sk = ib.ib_income_band_sk
WHERE 
    fr.total_net_paid > (SELECT AVG(total_net_paid) FROM sales_summary)
ORDER BY 
    fr.total_net_paid DESC;
