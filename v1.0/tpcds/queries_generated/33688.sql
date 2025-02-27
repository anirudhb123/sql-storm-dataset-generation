
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        cs.cs_sales_price AS sales_price,
        cs.cs_item_sk,
        cs.cs_order_number,
        1 AS level
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sales_price > 0
    UNION ALL
    SELECT 
        cs.cs_sales_price * 1.1 AS sales_price,
        cs.cs_item_sk,
        cs.cs_order_number,
        sh.level + 1
    FROM 
        catalog_sales cs
    JOIN 
        SalesHierarchy sh ON cs.cs_item_sk = sh.cs_item_sk
    WHERE 
        sh.level < 5
),
CustomerReturns AS (
    SELECT 
        wr_return_amt_inc_tax AS return_amt,
        wr_item_sk,
        wr_returning_customer_sk,
        COUNT(*) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk, wr_item_sk, wr_return_amt_inc_tax
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(NULLIF(AVG(d.cd_purchase_estimate), 0), 1) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_item_sk) AS item_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    si.sales_price,
    SUM(sd.total_sales) OVER (PARTITION BY ci.c_customer_id ORDER BY si.level) AS cumulative_sales,
    COALESCE(cr.return_count, 0) AS total_returns,
    CASE 
        WHEN COALESCE(cr.return_count, 0) > 0 THEN 'Returning'
        ELSE 'New'
    END AS customer_status
FROM 
    CustomerInfo ci
JOIN 
    SalesData sd ON ci.c_customer_id = sd.ws_order_number
LEFT JOIN 
    SalesHierarchy si ON si.cs_item_sk = sd.wr_item_sk
LEFT JOIN 
    CustomerReturns cr ON ci.c_customer_id = cr.wr_returning_customer_sk
WHERE 
    ci.avg_purchase_estimate BETWEEN 100 AND 10000
ORDER BY 
    cumulative_sales DESC;
