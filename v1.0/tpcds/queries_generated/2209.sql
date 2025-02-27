
WITH RecentSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '30 days') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE)
    GROUP BY 
        ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
StorePerformance AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COUNT(DISTINCT ss_ticket_number) AS total_sales_transactions,
        AVG(ss_net_paid) AS avg_sale_amount
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE)))
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    HV.c_customer_sk,
    HV.c_first_name,
    HV.c_last_name,
    HV.cd_gender,
    SP.s_store_name,
    SP.total_sales_transactions,
    SP.avg_sale_amount,
    RS.total_quantity,
    RS.total_net_paid
FROM 
    HighValueCustomers HV
LEFT JOIN 
    StorePerformance SP ON SP.total_sales_transactions > 0
LEFT JOIN 
    RecentSales RS ON RS.ws_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = HV.c_customer_sk)
WHERE 
    HV.purchase_rank <= 10
ORDER BY 
    HV.cd_purchase_estimate DESC, 
    SP.total_sales_transactions DESC;
