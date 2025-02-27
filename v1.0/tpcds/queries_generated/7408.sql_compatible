
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        dd.d_year = 2022
        AND ib.ib_lower_bound >= 50000
        AND ib.ib_upper_bound < 100000
    GROUP BY 
        ws.web_site_id
),
WarehouseAnalysis AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales_amount
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_warehouse_id = w.w_warehouse_id
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.total_orders,
    sd.total_quantity,
    sd.avg_sales_price,
    sd.total_discount,
    sd.total_tax,
    wa.total_store_sales,
    wa.total_store_sales_amount
FROM 
    SalesData sd
LEFT JOIN 
    WarehouseAnalysis wa ON sd.web_site_id = (
        SELECT DISTINCT ws.web_site_id
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk IN (
            SELECT c.c_customer_sk
            FROM customer c
            WHERE c.c_current_cdemo_sk IN (
                SELECT cd.cd_demo_sk
                FROM customer_demographics cd
                WHERE cd.cd_gender = 'F'
            )
        )
    )
ORDER BY 
    sd.total_sales DESC;
