
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        ws.web_site_sk
),
TopWebsites AS (
    SELECT 
        w.w_warehouse_id, 
        w.w_warehouse_name, 
        r.total_sales
    FROM 
        RankedSales r
    JOIN 
        warehouse w ON r.web_site_sk = w.w_warehouse_sk
    WHERE 
        r.sales_rank <= 5
),
SalesByStore AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_ext_sales_price) AS store_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
),
ReturnsSummary AS (
    SELECT 
        sr_store_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)
SELECT 
    t.website_id,
    t.warehouse_name,
    COALESCE(s.store_sales, 0) AS store_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_value, 0) AS total_return_value
FROM 
    TopWebsites t
LEFT JOIN 
    SalesByStore s ON t.warehouse_id = s.ss_store_sk
LEFT JOIN 
    ReturnsSummary r ON s.ss_store_sk = r.sr_store_sk
ORDER BY 
    t.total_sales DESC, 
    s.store_sales DESC;
