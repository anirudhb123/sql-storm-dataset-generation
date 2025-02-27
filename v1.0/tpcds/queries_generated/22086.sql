
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status IN ('M', 'S')
        AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.web_site_sk
),
FilteredReturns AS (
    SELECT 
        r.ws_item_sk,
        COUNT(*) AS total_returns,
        SUM(r.wr_return_amt) AS total_return_amount
    FROM 
        web_returns r
    WHERE 
        r.wr_returned_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        r.ws_item_sk
),
SalesWithReturns AS (
    SELECT 
        s.web_site_sk,
        s.total_sales,
        s.order_count,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_amount, 0.00) AS total_return_amount
    FROM 
        RankedSales s
    LEFT JOIN 
        FilteredReturns r ON s.web_site_sk = r.ws_item_sk
)
SELECT 
    w.w_warehouse_id,
    s.total_sales,
    s.order_count,
    s.total_returns,
    s.total_return_amount,
    CASE 
        WHEN s.total_sales > 0 THEN ROUND((s.total_return_amount / s.total_sales) * 100, 2)
        ELSE NULL 
    END AS return_percentage
FROM 
    SalesWithReturns s
JOIN 
    warehouse w ON w.w_warehouse_sk = (SELECT inv.inv_warehouse_sk 
                                        FROM inventory inv 
                                        WHERE inv.inv_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d))
GROUP BY 
    w.w_warehouse_id, s.total_sales, s.order_count, s.total_returns, s.total_return_amount
HAVING 
    s.order_count > 10 OR (s.total_sales < 1000 AND s.total_returns > 0)
ORDER BY 
    return_percentage DESC NULLS LAST;
