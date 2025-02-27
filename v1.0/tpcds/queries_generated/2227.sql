
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_net_paid_inc_tax + ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        CASE 
            WHEN cd.cd_income_band_sk IS NULL THEN 'Unknown'
            ELSE 'Known'
        END AS income_status
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_store_sales,
        cs.total_web_sales,
        cs.store_transactions,
        cs.web_transactions,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.income_status,
        DENSE_RANK() OVER (ORDER BY cs.total_store_sales + cs.total_web_sales DESC) AS total_sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        CustomerDemographics cd ON cs.c_customer_id = cd.c_customer_id
    WHERE 
        cs.sales_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_store_sales, 0) AS total_store_sales,
    COALESCE(tc.total_web_sales, 0) AS total_web_sales,
    tc.store_transactions,
    tc.web_transactions,
    tc.cd_gender,
    tc.cd_marital_status,
    CASE 
        WHEN tc.total_store_sales > 1000 AND tc.total_web_sales > 500 THEN 'High Value Customer'
        WHEN tc.total_store_sales BETWEEN 500 AND 1000 OR tc.total_web_sales BETWEEN 250 AND 500 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    TopCustomers tc
ORDER BY 
    total_sales_rank;
