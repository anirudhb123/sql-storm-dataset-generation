
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.bill_customer_sk,
        ws.item_sk,
        ws.order_number,
        ws.quantity,
        ws.sales_price,
        ws.ext_sales_price,
        ROW_NUMBER() OVER(PARTITION BY ws.bill_customer_sk ORDER BY ws.order_number) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
CustomerStats AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        AVG(cd.cd_purchase_estimate) AS avg_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
),
ReturnStats AS (
    SELECT 
        sr.returned_date_sk,
        COUNT(sr.ticket_number) AS total_returns,
        SUM(sr.return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.returned_date_sk
),
SalesSummary AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(CASE WHEN ws_ext_discount_amt > 0 THEN 1 ELSE 0 END) AS discount_count
    FROM 
        store_sales
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    cs.cd_demo_sk, 
    cs.customer_count,
    cs.male_count,
    cs.female_count,
    cs.avg_estimate,
    COALESCE(rv.total_returns, 0) AS total_returns,
    COALESCE(rv.total_return_amount, 0) AS total_return_amount,
    ss.store_name,
    ss.total_sales,
    ss.discount_count
FROM 
    CustomerStats cs
LEFT JOIN 
    ReturnStats rv ON rv.returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
JOIN 
    SalesSummary ss ON ss.s_store_sk = (SELECT s_store_sk FROM store LIMIT 1)
ORDER BY 
    cs.customer_count DESC
LIMIT 100;
