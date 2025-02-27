
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id, ws.web_site_sk
),
TopWebSites AS (
    SELECT 
        web_site_id, 
        total_sales, 
        total_orders
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    JOIN 
        web_sales ws ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
    GROUP BY 
        wr.returning_customer_sk
),
ReturnToSalesRatio AS (
    SELECT 
        c.returning_customer_sk,
        COALESCE(SUM(CASE WHEN ws.total_sales IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_sales_count,
        COALESCE(SUM(wr.total_returns), 0) AS total_returns_count,
        COALESCE(SUM(wr.total_return_amount), 0) AS total_return_amount
    FROM 
        CustomerReturns cr
    LEFT JOIN 
        (
            SELECT 
                ws_bill_customer_sk AS customer_sk, 
                SUM(ws.ws_ext_sales_price) AS total_sales
            FROM 
                web_sales ws
            GROUP BY 
                ws_bill_customer_sk
        ) ws ON cr.returning_customer_sk = ws.customer_sk
    GROUP BY 
        cr.returning_customer_sk
)
SELECT 
    ws.web_site_id,
    twr.total_sales,
    twr.total_orders,
    r.customer_sk,
    r.total_sales_count,
    r.total_returns_count,
    r.total_return_amount,
    CASE 
        WHEN r.total_returns_count = 0 THEN 0 
        ELSE (r.total_return_amount / NULLIF(ws.total_sales, 0)) * 100 
    END AS return_percentage
FROM 
    TopWebSites twr 
JOIN 
    ReturnToSalesRatio r ON twr.web_site_id = (SELECT web_site_id FROM web_sales WHERE ws_bill_customer_sk = r.returning_customer_sk LIMIT 1)
ORDER BY 
    twr.total_sales DESC;
