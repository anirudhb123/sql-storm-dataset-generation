
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        0 AS depth
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        depth + 1
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesHierarchy sh ON c.c_current_cdemo_sk = sh.c_current_cdemo_sk
    WHERE 
        sh.depth < 3 
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023
        ) AND (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
        )
    GROUP BY 
        ws_bill_customer_sk
),
ReturnsSummary AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returns,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
FinalSummary AS (
    SELECT 
        sh.c_first_name,
        sh.c_last_name,
        sd.total_sales,
        rs.total_returns,
        COALESCE(sd.total_sales, 0) - COALESCE(rs.total_returns, 0) AS net_sales,
        CASE 
            WHEN COALESCE(sd.total_sales, 0) = 0 THEN 0 
            ELSE (COALESCE(sd.total_sales, 0) / (COALESCE(sd.total_sales, 0) + COALESCE(rs.total_returns, 0))) * 100 
        END AS sales_to_return_ratio
    FROM 
        SalesHierarchy sh
    LEFT JOIN 
        SalesData sd ON sh.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN 
        ReturnsSummary rs ON sh.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(sales_to_return_ratio, 0) AS sales_to_return_ratio,
    COALESCE(net_sales, 0) AS net_sales,
    ROW_NUMBER() OVER (ORDER BY net_sales DESC) AS sales_rank
FROM 
    FinalSummary f
JOIN 
    customer c ON f.c_first_name = c.c_first_name AND f.c_last_name = c.c_last_name
WHERE 
    f.sales_to_return_ratio < 100
ORDER BY 
    net_sales DESC;
