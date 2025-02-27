
WITH RankedSales AS (
    SELECT 
        s_store_sk,
        s_ticket_number,
        ss_quantity,
        ss_net_paid,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY ss_net_paid DESC) AS rank
    FROM 
        store_sales
),
HighValueCustomers AS (
    SELECT 
        c.customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(cd.cd_purchase_estimate, 0) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        COALESCE(cd.cd_purchase_estimate, 0) > 500
),
SalesReturnSummary AS (
    SELECT 
        sr_store_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_return_quantity,
        AVG(sr_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AggregateData AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.net_paid) AS total_store_sales,
        COALESCE(SUM(rs.ss_quantity), 0) AS total_quantity,
        COALESCE(SUM(wss.total_web_sales), 0) AS total_web_sales,
        rc.total_returns,
        rc.total_return_quantity,
        CASE 
            WHEN SUM(ss.net_paid) > 10000 THEN 'High Value Store'
            WHEN SUM(ss.net_paid) BETWEEN 5000 AND 10000 THEN 'Medium Value Store'
            ELSE 'Low Value Store'
        END AS store_value_category
    FROM 
        store_sales ss
    LEFT JOIN 
        SalesReturnSummary rc ON ss.ss_store_sk = rc.sr_store_sk
    LEFT JOIN 
        RankedSales rs ON ss.s_store_sk = rs.s_store_sk
    LEFT JOIN 
        WebSalesSummary wss ON ss.ss_customer_sk = wss.ws_bill_customer_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    ad.s_store_sk,
    ad.store_value_category,
    COUNT(DISTINCT hvc.customer_sk) AS high_value_customers,
    MAX(ad.total_store_sales) AS max_store_sales
FROM 
    AggregateData ad
LEFT JOIN 
    HighValueCustomers hvc ON ad.s_store_sk = hvc.customer_sk
WHERE 
    ad.total_store_sales IS NOT NULL
GROUP BY 
    ad.s_store_sk, 
    ad.store_value_category
HAVING 
    MAX(ad.total_store_sales) < (SELECT AVG(total_store_sales) FROM AggregateData);
