
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND ws_sold_date_sk BETWEEN 2458855 AND 2459187 -- Example date range
    GROUP BY 
        ws.web_site_id, ws_sold_date_sk
),
TopSales AS (
    SELECT 
        web_site_id, 
        total_sales, 
        total_orders
    FROM 
        SalesData
    WHERE 
        sales_rank <= 5
),
RefundData AS (
    SELECT 
        cr_return_date_sk,
        SUM(cr_return_amount) AS total_refund_amount,
        COUNT(cr_order_number) AS total_refunds
    FROM 
        catalog_returns
    GROUP BY 
        cr_return_date_sk
),
CombinedData AS (
    SELECT 
        ts.web_site_id,
        ts.total_sales,
        ts.total_orders,
        COALESCE(SUM(rd.total_refund_amount), 0) AS total_refunds,
        ts.total_sales - COALESCE(SUM(rd.total_refund_amount), 0) AS net_sales
    FROM 
        TopSales ts
    LEFT JOIN 
        RefundData rd ON ts.web_site_id = rd.cr_return_date_sk
    GROUP BY 
        ts.web_site_id, ts.total_sales, ts.total_orders
)
SELECT 
    cb.web_site_id,
    cb.total_sales,
    cb.total_orders,
    cb.total_refunds,
    cb.net_sales,
    CASE 
        WHEN cb.net_sales > 0 THEN (cb.net_sales / cb.total_sales) * 100
        ELSE 0 
    END AS refund_percentage
FROM 
    CombinedData cb
ORDER BY 
    cb.net_sales DESC;

