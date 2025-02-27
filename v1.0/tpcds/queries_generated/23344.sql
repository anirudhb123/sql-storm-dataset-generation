
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, ws.web_site_id, ws_sold_date_sk
),
customer_return_summary AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS unique_returns,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
external_sales AS (
    SELECT 
        cs.bill_customer_sk,
        SUM(cs.net_paid) AS external_net_paid
    FROM 
        catalog_sales cs
    WHERE 
        cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 6)
    GROUP BY 
        cs.bill_customer_sk
),
customer_demographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(s.total_net_paid, 0) AS total_sales,
    COALESCE(r.unique_returns, 0) AS unique_returns,
    COALESCE(r.total_returned_quantity, 0) AS total_returned_quantity,
    CASE 
        WHEN s.total_net_paid IS NULL THEN 'No Sales'
        WHEN r.unique_returns > 0 THEN 'Returned'
        ELSE 'Active'
    END AS customer_status,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(s.total_net_paid, 0) DESC) AS gender_sales_rank
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    ranked_sales s ON c.c_customer_sk = s.web_site_sk
LEFT JOIN 
    customer_return_summary r ON c.c_customer_sk = r.wr_returning_customer_sk
WHERE 
    cd.cd_purchase_estimate > 100
    AND (cd.cd_marital_status IS NOT NULL OR cd.cd_gender IS NOT NULL)
ORDER BY 
    customer_status, total_sales DESC
LIMIT 100;
