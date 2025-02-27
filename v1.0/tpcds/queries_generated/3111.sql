
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_refunds
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
NetSales AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_sold_date_sk,
        rs.total_quantity,
        rs.total_sales - COALESCE(cr.total_refunds, 0) AS net_sales
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.web_site_sk = cr.wr_returning_customer_sk
)
SELECT 
    ws.warehouse_sk,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(ns.net_sales) AS total_net_sales,
    AVG(ns.total_quantity) AS avg_quantity_per_order,
    STDEV(ns.total_quantity) AS stdev_quantity_per_order
FROM 
    NetSales ns
JOIN 
    inventory i ON ns.web_site_sk = i.inv_warehouse_sk
JOIN 
    catalog_sales cs ON ns.ws_sold_date_sk = cs.cs_sold_date_sk
JOIN 
    warehouse ws ON i.inv_warehouse_sk = ws.warehouse_sk
WHERE 
    ns.net_sales > 0
GROUP BY 
    ws.warehouse_sk
HAVING 
    COUNT(DISTINCT cs.cs_order_number) > 10
ORDER BY 
    total_net_sales DESC;
