
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.ss_order_number) AS store_order_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_store_spent,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_spent,
        COALESCE(SUM(CASE WHEN sr.returned_date_sk IS NOT NULL THEN sr.return_quantity ELSE 0 END), 0) AS total_store_returns,
        COALESCE(SUM(CASE WHEN wr.returned_date_sk IS NOT NULL THEN wr.return_quantity ELSE 0 END), 0) AS total_web_returns
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
IncomeAnalysis AS (
    SELECT 
        hd.hd_demo_sk,
        COUNT(*) AS household_count,
        AVG(hd.hd_dep_count) AS avg_dep_count,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_sold_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        ws.ws_sold_date_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.store_order_count,
    cs.web_order_count,
    cs.total_store_spent,
    cs.total_web_spent,
    ia.household_count,
    ia.avg_dep_count,
    ia.avg_vehicle_count,
    ss.total_web_sales,
    ss.total_store_sales,
    ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_web_spent DESC) AS ranking,
    CASE 
        WHEN cs.total_store_spent > cs.total_web_spent THEN 'Additional Store Purchases' 
        WHEN cs.total_web_spent > cs.total_store_spent THEN 'More Web Purchases' 
        ELSE 'Equal Spending'
    END AS spending_comparison
FROM 
    CustomerStats cs
LEFT JOIN 
    IncomeAnalysis ia ON cs.c_customer_sk = ia.hd_demo_sk
LEFT JOIN 
    SalesSummary ss ON ss.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date <= CURRENT_DATE)
WHERE 
    cs.total_store_spent IS NOT NULL
    OR cs.total_web_spent IS NOT NULL
ORDER BY 
    cs.store_order_count DESC, 
    cs.web_order_count DESC;
