
WITH RECURSIVE SalesAnalysis AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws_sold_date_sk DESC) AS recent_sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws_net_profit > 0
    UNION ALL
    SELECT 
        ws.web_site_id,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sold_date_sk) DESC) AS recent_sales_rank
    FROM 
        web_sales ws
    JOIN 
        SalesAnalysis sa ON ws.web_site_id = sa.web_site_id
    GROUP BY 
        ws.web_site_id, ws.web_name
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_customer_sk) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_returned_date_sk
),
SalesStats AS (
    SELECT 
        dd.d_year,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_sales,
        COALESCE(cr.total_return_amount, 0) AS total_returns,
        COUNT(DISTINCT cr.return_count) AS total_customers_returned
    FROM 
        date_dim dd
    LEFT JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        CustomerReturns cr ON dd.d_date_sk = cr.sr_returned_date_sk
    GROUP BY 
        dd.d_year
)
SELECT 
    s.d_year,
    s.total_orders,
    s.total_sales,
    s.total_returns,
    CASE 
        WHEN s.total_orders = 0 THEN NULL
        ELSE ROUND((s.total_returns / s.total_orders) * 100, 2)
    END AS percentage_returns,
    rank() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM 
    SalesStats s
ORDER BY 
    s.d_year DESC
FETCH FIRST 10 ROWS ONLY;
