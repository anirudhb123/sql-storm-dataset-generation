
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
TopWebSites AS (
    SELECT 
        web_site_sk,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        wr_order_number,
        SUM(COALESCE(wr_return_amt, 0)) AS total_return_amount,
        SUM(COALESCE(wr_return_quantity, 0)) AS total_return_quantity
    FROM 
        web_returns
    GROUP BY 
        wr_order_number
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        COUNT(ss.ss_ticket_number) AS total_sales_count,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk IN (SELECT DISTINCT dd.d_date_sk FROM date_dim dd WHERE dd.d_year = 2023)
    GROUP BY 
        ss.ss_store_sk
)

SELECT 
    wa.w_warehouse_id,
    wa.w_warehouse_name,
    COALESCE(ts.total_sales, 0) AS web_sales_for_warehouse,
    cs.total_sales_count AS store_sales_count,
    SUM(COALESCE(cs.total_net_paid, 0)) AS total_store_net_paid,
    SUM(COALESCE(cr.total_return_amount, 0)) AS total_returns
FROM 
    warehouse wa
LEFT JOIN 
    TopWebSites ts ON ts.web_site_sk = wa.w_warehouse_sk
LEFT JOIN 
    StoreSalesSummary cs ON wa.w_warehouse_sk = cs.ss_store_sk
LEFT JOIN 
    CustomerReturns cr ON cr.wr_order_number = cs.ss_ticket_number
GROUP BY 
    wa.w_warehouse_id, wa.w_warehouse_name, ts.total_sales, cs.total_sales_count
ORDER BY 
    web_sales_for_warehouse DESC, total_store_net_paid DESC;
