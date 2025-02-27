
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, hd.hd_income_band_sk
), sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
), rb AS (
    SELECT 
        cs.cs_bill_customer_sk,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs.cs_net_profit) AS total_catalog_profit
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_bill_customer_sk
)

SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_purchase_estimate,
    cs.hd_income_band_sk,
    cs.total_returns,
    cs.total_returned_amount,
    COALESCE(ss.total_sales, 0) AS total_web_sales,
    COALESCE(ss.total_profit, 0) AS total_web_profit,
    COALESCE(rb.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(rb.total_catalog_profit, 0) AS total_catalog_profit
FROM 
    customer_summary cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_id = ss.ws_bill_customer_sk
LEFT JOIN 
    rb ON cs.c_customer_id = rb.cs_bill_customer_sk
WHERE 
    cs.total_returns > 0 OR ss.total_orders > 0
ORDER BY 
    cs.total_returned_amount DESC
LIMIT 100;
