
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        0 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'

    UNION ALL

    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ch.level + 1
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer c ON ch.c_customer_sk = c.c_current_cdemo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
), 
ReturnsSummary AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
), 
CustomerSalesReturns AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ss.total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount
    FROM 
        CustomerHierarchy ch
    LEFT JOIN 
        SalesSummary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN 
        ReturnsSummary rs ON ch.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    cs.total_sales,
    cs.total_returns,
    cs.total_return_amount,
    CASE 
        WHEN cs.total_sales > 1000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    CustomerSalesReturns cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE 
    c.c_birth_month = (SELECT MAX(COALESCE(c.birth_month, 1)) FROM customer c)
ORDER BY 
    cs.total_sales DESC, cs.total_returns ASC
LIMIT 50;
