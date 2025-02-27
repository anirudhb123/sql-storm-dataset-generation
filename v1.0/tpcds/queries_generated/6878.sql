
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
RankedCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cs.last_purchase_date,
        ROW_NUMBER() OVER (PARTITION BY cs.ib_income_band_sk ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    rc.c_customer_id,
    rc.total_sales,
    rc.order_count,
    rc.last_purchase_date,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    RankedCustomers rc
JOIN 
    customer_demographics cd ON rc.c_customer_id = cd.cd_demo_sk
JOIN 
    household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    rc.sales_rank <= 10
ORDER BY 
    rc.total_sales DESC;
