
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_return_value,
        AVG(sr.return_quantity) AS avg_return_qty,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(sr.return_amt) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_returns,
        cs.total_return_value,
        CASE 
            WHEN cs.gender_rank = 1 THEN 'Top Performer'
            WHEN cs.gender_rank BETWEEN 2 AND 5 THEN 'Mid Tier'
            ELSE 'Minor Contributor'
        END AS performance_category
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_return_value IS NOT NULL
    AND
        (cs.total_returns > 5 OR cs.total_return_value > 1000)
),
SalesAnalysis AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(CASE WHEN ws.ws_ext_discount_amt > 0 THEN 1 ELSE 0 END) AS discount_count,
        AVG(ws.ws_ext_sales_price) AS avg_sales_price_per_item
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk > 0
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.total_returns,
    tc.total_return_value,
    tc.performance_category,
    sa.total_sales,
    sa.discount_count,
    sa.avg_sales_price_per_item,
    COALESCE(sa.total_sales / NULLIF(tc.total_returns, 0), 0) AS sales_per_return_ratio
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesAnalysis sa ON tc.c_customer_id = sa.ws_bill_customer_sk
WHERE 
    (tc.performance_category = 'Top Performer' AND sa.total_sales > 10000)
OR 
    (tc.performance_category = 'Mid Tier' AND sa.discount_count > 3)
ORDER BY 
    tc.performance_category, sa.total_sales DESC;
