
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_tickets
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
IncomeBandSales AS (
    SELECT 
        h.hd_income_band_sk,
        SUM(cs.total_web_sales) AS total_income_web_sales,
        SUM(cs.total_store_sales) AS total_income_store_sales
    FROM 
        household_demographics h
    JOIN 
        CustomerSales cs ON h.hd_demo_sk = cs.c_customer_sk
    GROUP BY 
        h.hd_income_band_sk
),
IncomeBandRanges AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE 
            WHEN total_income_web_sales IS NULL THEN 0 
            ELSE total_income_web_sales 
        END AS web_sales_with_nulls,
        CASE 
            WHEN total_income_store_sales IS NULL THEN 0 
            ELSE total_income_store_sales 
        END AS store_sales_with_nulls
    FROM 
        IncomeBandSales ib
    LEFT JOIN 
        IncomeBandSales s ON ib.ib_income_band_sk = s.hd_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(web_sales_with_nulls) AS aggregate_web_sales,
    SUM(store_sales_with_nulls) AS aggregate_store_sales
FROM 
    IncomeBandRanges ib
GROUP BY 
    ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
HAVING 
    SUM(web_sales_with_nulls) > 0 OR SUM(store_sales_with_nulls) > 0
ORDER BY 
    ib.ib_income_band_sk;
