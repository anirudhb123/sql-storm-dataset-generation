
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk, d.d_year, d.d_month_seq, d.d_quarter_seq
),
CustomerSegments AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        SUM(cs.cs_sales_price) AS catalog_sales
    FROM
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
FinalReport AS (
    SELECT 
        sd.d_year,
        sd.d_month_seq,
        sd.d_quarter_seq,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.hd_income_band_sk,
        SUM(sd.total_quantity) AS total_web_quantity,
        SUM(sd.total_sales) AS total_web_sales,
        SUM(cs.total_catalog_orders) AS total_catalog_orders,
        SUM(cs.catalog_sales) AS total_catalog_sales
    FROM 
        SalesData sd
    LEFT JOIN 
        CustomerSegments cs ON cs.c_customer_sk = (
            SELECT 
                c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk IN (
                    SELECT DISTINCT c.c_current_addr_sk FROM customer c WHERE c.c_current_addr_sk = cs.c_customer_sk
                ) LIMIT 1
        )
    GROUP BY 
        sd.d_year, sd.d_month_seq, sd.d_quarter_seq, cs.cd_gender, cs.cd_marital_status, cs.hd_income_band_sk
)
SELECT 
    d_year,
    d_month_seq,
    d_quarter_seq,
    cd_gender,
    cd_marital_status,
    hd_income_band_sk,
    total_web_quantity,
    total_web_sales,
    total_catalog_orders,
    total_catalog_sales
FROM 
    FinalReport
ORDER BY 
    d_year, d_month_seq, d_quarter_seq, cd_gender, cd_marital_status, hd_income_band_sk;
