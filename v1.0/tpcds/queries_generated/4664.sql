
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        sr.c_customer_id,
        sr.c_first_name,
        sr.c_last_name,
        sr.total_sales,
        sr.order_count
    FROM 
        SalesRanked sr
    JOIN 
        CustomerDemographics cd ON sr.c_customer_id IN (
            SELECT 
                c.c_customer_id 
            FROM 
                customer c
            WHERE 
                c.c_current_cdemo_sk IN (
                    SELECT 
                        cd.cd_demo_sk 
                    FROM 
                        CustomerDemographics 
                    WHERE 
                        hd_income_band_sk = (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound >= 100000)
                )
        )
    WHERE 
        sr.sales_rank <= 10
)
SELECT 
    hvc.c_customer_id,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.order_count,
    CASE 
        WHEN hvc.total_sales IS NULL THEN 'No Sales'
        WHEN hvc.total_sales > 1000 THEN 'Premium'
        ELSE 'Regular'
    END AS customer_classification
FROM 
    HighValueCustomers hvc
ORDER BY 
    hvc.total_sales DESC;
