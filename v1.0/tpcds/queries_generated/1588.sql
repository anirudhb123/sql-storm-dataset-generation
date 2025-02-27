
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS spend_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1970
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpendingCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.total_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.spend_rank <= 10 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_income_band_sk IN (
            SELECT ib.ib_income_band_sk 
            FROM income_band ib
            WHERE ib.ib_lower_bound >= 50000
        )
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_sales
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk = (
            SELECT max(ss1.ss_sold_date_sk)
            FROM store_sales ss1
        )
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    hsc.c_first_name || ' ' || hsc.c_last_name AS customer_name,
    s.s_store_id,
    s.s_store_name,
    ss.total_sales,
    hsc.total_spent
FROM 
    HighSpendingCustomers hsc
JOIN 
    store s ON hsc.c_customer_sk = s.s_store_sk
JOIN 
    StoreSalesSummary ss ON s.s_store_sk = ss.ss_store_sk
WHERE 
    ss.total_sales > 1000
ORDER BY 
    hsc.total_spent DESC;
