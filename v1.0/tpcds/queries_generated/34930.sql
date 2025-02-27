
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ss_store_sk,
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_customer_sk
    HAVING 
        SUM(ss_ext_sales_price) > 1000
    UNION ALL
    SELECT 
        s.ss_store_sk,
        p.ws_bill_customer_sk,
        SUM(s.ss_ext_sales_price) + SUM(p.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT s.ss_ticket_number) + COUNT(DISTINCT p.ws_order_number) AS total_transactions,
        level + 1
    FROM 
        store_sales s
    JOIN 
        web_sales p ON s.ss_customer_sk = p.ws_bill_customer_sk
    GROUP BY 
        s.ss_store_sk, p.ws_bill_customer_sk, level
), SalesDetails AS (
    SELECT 
        sh.ss_store_sk,
        ca.ca_city,
        SUM(sh.total_sales) AS aggregate_sales,
        AVG(sh.total_transactions) AS avg_transactions
    FROM 
        SalesHierarchy sh
    LEFT JOIN 
        customer c ON sh.ss_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        sh.ss_store_sk, ca.ca_city
), FinalReport AS (
    SELECT 
        store.w_warehouse_id,
        sd.ca_city,
        sd.aggregate_sales,
        RANK() OVER (PARTITION BY sd.ca_city ORDER BY sd.aggregate_sales DESC) AS sales_rank
    FROM 
        SalesDetails sd
    JOIN 
        warehouse store ON sd.ss_store_sk = store.w_warehouse_sk
)
SELECT 
    fr.w_warehouse_id,
    fr.ca_city,
    fr.aggregate_sales,
    fr.sales_rank,
    COALESCE(band.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(band.ib_upper_bound, 999999) AS income_upper_bound
FROM 
    FinalReport fr
LEFT JOIN 
    household_demographics hd ON fr.ss_store_sk = hd.hd_demo_sk
LEFT JOIN 
    income_band band ON hd.hd_income_band_sk = band.ib_income_band_sk
WHERE 
    fr.sales_rank <= 10 
ORDER BY 
    fr.ca_city, fr.sales_rank;
