
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_dep_count IS NOT NULL
        AND (cd.cd_gender = 'M' OR cd.cd_gender IS NULL)
    GROUP BY 
        ws.web_site_sk
),
SalesStats AS (
    SELECT 
        w.warehouse_sk,
        SUM(ws.total_sales) AS warehouse_sales,
        SUM(rs.total_orders) AS warehouse_orders
    FROM 
        warehouse w
    LEFT JOIN 
        RankedSales rs ON w.warehouse_sk = rs.web_site_sk
    GROUP BY 
        w.warehouse_sk
),
ReturnSummary AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
)
SELECT 
    s.warehouse_sk, 
    s.warehouse_sales,
    s.warehouse_orders,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_returned_amt, 0) AS total_returned_amt,
    CASE 
        WHEN s.warehouse_orders > 0 THEN 
            ROUND((COALESCE(r.total_returned_amt, 0) / NULLIF(s.warehouse_sales, 0)) * 100, 2)
        ELSE 0 
    END AS return_percentage
FROM 
    SalesStats s
LEFT JOIN 
    ReturnSummary r ON s.warehouse_sk = r.sr_item_sk
WHERE 
    r.total_returned_amt IS NULL OR r.total_returned_amt > (SELECT AVG(total_returned_amt) FROM ReturnSummary)
ORDER BY 
    return_percentage DESC, 
    s.warehouse_sales DESC;
