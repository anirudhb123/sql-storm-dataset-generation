
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_ship_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws_bill_customer_sk, 
        ws_ship_customer_sk
), CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        r.r_reason_desc
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
), TopCustomers AS (
    SELECT 
        rd.ws_bill_customer_sk,
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        rd.total_sales,
        rd.total_orders
    FROM 
        RankedSales rd
    JOIN 
        CustomerDetails cd ON rd.ws_bill_customer_sk = cd.c_customer_id
    WHERE 
        rd.sales_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    cd.cd_gender,
    cd.cd_income_band_sk,
    cd.hd_buy_potential,
    cd.hd_dep_count
FROM 
    TopCustomers tc
JOIN 
    CustomerDetails cd ON tc.c_customer_id = cd.c_customer_id
ORDER BY 
    total_sales DESC;
