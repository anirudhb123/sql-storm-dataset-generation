
WITH RecursiveSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
    UNION ALL
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_order_number) AS rn
    FROM 
        catalog_sales cs
    JOIN 
        RecursiveSales rs ON cs.cs_item_sk = rs.ws_item_sk AND rs.rn = 1
),
FilteredReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COALESCE(SUM(sr.sr_return_tax), 0) AS total_return_tax
    FROM 
        store_returns sr
    JOIN 
        RecursiveSales rs ON rs.ws_item_sk = sr.sr_item_sk
    WHERE 
        sr.sr_return_quantity > 0
    GROUP BY 
        sr.sr_item_sk
),
IncomeEstimates AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(COALESCE(cd.cd_purchase_estimate, 0)) AS total_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status IS NOT NULL
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    dd.d_year,
    SUM(fr.total_return_amt) AS total_returns,
    SUM(fr.total_return_tax) AS total_tax,
    STRING_AGG(DISTINCT CONCAT('Item:', rs.ws_item_sk, ', Qty:', rs.ws_quantity), '; ') AS item_summary,
    ie.total_purchase_estimate,
    ie.customer_count
FROM 
    FilteredReturns fr
JOIN 
    date_dim dd ON dd.d_date_sk BETWEEN (SELECT MIN(sr_returned_date_sk) FROM store_returns) AND (SELECT MAX(sr_returned_date_sk) FROM store_returns)
LEFT JOIN 
    IncomeEstimates ie ON dd.d_year = (SELECT d_year FROM date_dim WHERE d_date_sk = fr.sr_item_sk) 
LEFT JOIN 
    RecursiveSales rs ON rs.ws_item_sk = fr.sr_item_sk
WHERE 
    fr.total_returns > 0 
GROUP BY 
    dd.d_year, ie.total_purchase_estimate, ie.customer_count
HAVING 
    SUM(fr.total_return_amt) > (SELECT AVG(total_return_amt) FROM FilteredReturns)
ORDER BY 
    dd.d_year;
