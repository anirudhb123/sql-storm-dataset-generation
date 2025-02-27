
WITH RecentSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        r.ws_item_sk, 
        r.total_net_paid,
        r.total_orders,
        i.i_item_desc
    FROM 
        RecentSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank <= 10
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk AS customer_sk,
        SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        COALESCE(SUM(ws.ws_net_paid), 0) > 1000
),
ReturnsAnalysis AS (
    SELECT 
        rc.customer_sk,
        rc.total_return_amount,
        hv.total_spent,
        (rc.total_return_amount / NULLIF(hv.total_spent, 0)) * 100 AS return_ratio
    FROM 
        CustomerReturns rc
    JOIN 
        HighValueCustomers hv ON rc.customer_sk = hv.c_customer_sk
)
SELECT 
    t.i_item_desc,
    hv.c_first_name,
    hv.c_last_name,
    hv.total_spent,
    ra.total_return_amount,
    ra.return_ratio
FROM 
    TopItems t
JOIN 
    ReturnsAnalysis ra ON ra.customer_sk IN (SELECT c_customer_sk FROM customer)
JOIN 
    HighValueCustomers hv ON hv.c_customer_sk = ra.customer_sk
ORDER BY 
    ra.return_ratio DESC;
