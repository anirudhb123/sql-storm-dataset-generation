
WITH CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender IS NOT NULL 
        AND cd.cd_marital_status IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
SalesSummary AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_paid) AS store_total_sales
    FROM 
        store_sales AS ss
    JOIN 
        store AS s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        ss.ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_spent
    FROM 
        CustomerStatistics AS cs
    WHERE 
        cs.rank <= 10
)
SELECT 
    tc.c_first_name || ' ' || tc.c_last_name AS customer_name,
    tc.total_orders,
    tc.total_spent,
    COALESCE(ss.store_total_sales, 0) AS store_total_sales
FROM 
    TopCustomers AS tc
FULL OUTER JOIN 
    SalesSummary AS ss ON tc.c_customer_sk = ss.s_store_sk
WHERE 
    (tc.total_spent IS NOT NULL OR ss.store_total_sales IS NOT NULL)
ORDER BY 
    tc.total_spent DESC NULLS LAST;
