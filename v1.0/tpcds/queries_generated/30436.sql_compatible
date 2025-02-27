
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) + sc.total_quantity AS total_quantity,
        SUM(cs_net_paid) + sc.total_sales AS total_sales
    FROM 
        catalog_sales cs
    JOIN 
        Sales_CTE sc ON cs_sold_date_sk = sc.ws_sold_date_sk AND cs_item_sk = sc.ws_item_sk
    GROUP BY 
        cs_sold_date_sk, cs_item_sk, sc.total_quantity, sc.total_sales
),
Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_total.total_sales) AS total_web_sales,
        SUM(ss.total_sales) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        Sales_CTE ws_total ON ws_total.ws_item_sk = ws.ws_item_sk
    GROUP BY 
        c.c_customer_sk
),
Income_Bands AS (
    SELECT 
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(SUM(cs.total_web_sales), 0) AS total_web_sales,
    COALESCE(SUM(cs.total_store_sales), 0) AS total_store_sales,
    COUNT(cs.c_customer_sk) AS total_customers,
    SUM(CASE WHEN cs.web_order_count > 0 THEN cs.total_web_sales ELSE 0 END) AS total_web_sales_customers,
    SUM(CASE WHEN cs.store_order_count > 0 THEN cs.total_store_sales ELSE 0 END) AS total_store_sales_customers
FROM 
    Income_Bands ib
LEFT JOIN 
    Customer_Sales cs ON cs.c_customer_sk IN (
        SELECT c.c_customer_sk 
        FROM customer c 
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk 
        WHERE hd.hd_income_band_sk = ib.hd_income_band_sk
    )
GROUP BY 
    ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY 
    ib.ib_lower_bound;
