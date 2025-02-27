
WITH TotalSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
TotalReturns AS (
    SELECT 
        wr_returning_customer_sk AS customer_id,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        wr_returning_customer_sk
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        COALESCE(ts.total_sales, 0) AS total_sales,
        COALESCE(tr.total_return_amt, 0) AS total_returns,
        (COALESCE(ts.total_sales, 0) - COALESCE(tr.total_return_amt, 0)) AS net_sales,
        cd.cd_gender,
        CASE 
            WHEN cd_cd_marital_status = 'M' THEN 'Married' 
            ELSE 'Single' 
        END AS marital_status,
        COUNT(DISTINCT ws_order_number) AS unique_orders,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM 
        customer c
    LEFT JOIN 
        TotalSales ts ON c.c_customer_sk = ts.customer_id
    LEFT JOIN 
        TotalReturns tr ON c.c_customer_sk = tr.customer_id
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd_cd_marital_status
)
SELECT 
    cm.customer_id,
    cm.total_sales,
    cm.total_returns,
    cm.net_sales,
    cm.marital_status,
    cm.unique_orders,
    cm.unique_returns
FROM 
    CustomerMetrics cm
ORDER BY 
    cm.net_sales DESC
LIMIT 100;
