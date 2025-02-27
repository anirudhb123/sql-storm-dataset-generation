
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS num_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebSalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_web_sales_quantity,
        SUM(ws_net_paid_inc_tax) AS total_web_sales_amount,
        COUNT(DISTINCT ws_order_number) AS num_web_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        SUM(CASE WHEN cr.returned_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS has_returned,
        COUNT(DISTINCT w.web_site_sk) AS num_websites_accessed
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    LEFT JOIN 
        store_returns cr ON c.c_customer_sk = cr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
),
FinalResults AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COALESCE(SUM(cr.total_returned_quantity), 0) AS total_returned_quantity,
        COALESCE(SUM(ws.total_web_sales_quantity), 0) AS total_web_sales_quantity,
        COALESCE(SUM(cr.total_returned_amount), 0) AS total_returned_amount,
        COALESCE(SUM(ws.total_web_sales_amount), 0) AS total_web_sales_amount,
        COUNT(DISTINCT cd.num_websites_accessed) AS unique_websites_accessed
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        WebSalesDetails ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
)
SELECT 
    fr.c_customer_sk,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.cd_education_status,
    fr.cd_purchase_estimate,
    fr.total_returned_quantity,
    fr.total_web_sales_quantity,
    fr.total_returned_amount,
    fr.total_web_sales_amount,
    fr.unique_websites_accessed,
    ROW_NUMBER() OVER (PARTITION BY fr.cd_gender ORDER BY fr.total_web_sales_amount DESC) AS rank
FROM 
    FinalResults fr
WHERE 
    fr.total_returned_quantity > 0
    AND fr.unique_websites_accessed > 1
ORDER BY 
    fr.total_web_sales_amount DESC;
