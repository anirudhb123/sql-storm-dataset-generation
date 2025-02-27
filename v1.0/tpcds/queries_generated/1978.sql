
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.total_sales
    FROM 
        customer c
    JOIN 
        RankedSales r ON c.c_customer_sk = r.ws_bill_customer_sk
    WHERE 
        r.sales_rank = 1
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(hd.hd_vehicle_count) AS total_vehicle_count
    FROM 
        household_demographics hd
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
SalesAnalysis AS (
    SELECT 
        hvc.c_customer_id,
        hvc.c_first_name,
        hvc.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.total_vehicle_count, 0) AS total_vehicle_count,
        hvc.total_sales
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        CustomerDemographics cd ON hvc.c_customer_id = cd.cd_gender
),
StoreInfo AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_store_sk = s.s_store_sk) AS total_sales_count
    FROM 
        store s
    WHERE 
        s.s_rec_start_date <= CURRENT_DATE AND 
        (s.s_closed_date_sk IS NULL OR s.s_closed_date_sk > CURRENT_DATE)
)
SELECT 
    sa.c_customer_id,
    sa.c_first_name,
    sa.c_last_name,
    sa.cd_gender,
    sa.cd_marital_status,
    sa.total_vehicle_count,
    sa.total_sales,
    si.s_store_id,
    si.s_store_name,
    si.total_sales_count
FROM 
    SalesAnalysis sa
JOIN 
    StoreInfo si ON sa.total_sales > 5000
WHERE 
    EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_current_price > 50))
ORDER BY 
    sa.total_sales DESC, si.total_sales_count DESC;
