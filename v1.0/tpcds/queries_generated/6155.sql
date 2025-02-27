
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        SUM(cs.cs_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM 
        catalog_sales cs
    JOIN 
        web_sales ws ON cs.cs_order_number = ws.ws_order_number
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id, cs.cs_order_number, cs.cs_sold_date_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        SUM(sd.total_sales) AS customer_total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        SalesData sd ON c.c_customer_sk = sd.cs_order_number
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_income_band_sk, hd.hd_buy_potential
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_income_band_sk ORDER BY customer_total_sales DESC) AS sales_rank
    FROM 
        CustomerData
)
SELECT 
    rc.cd_gender,
    rc.cd_income_band_sk,
    COUNT(*) AS num_customers,
    AVG(rc.customer_total_sales) AS avg_sales,
    MAX(rc.customer_total_sales) AS max_sales
FROM 
    RankedCustomers rc
WHERE 
    rc.sales_rank <= 10
GROUP BY 
    rc.cd_gender, rc.cd_income_band_sk
ORDER BY 
    rc.cd_income_band_sk, avg_sales DESC;
