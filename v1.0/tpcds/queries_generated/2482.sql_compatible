
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id, ws.ws_sold_date_sk
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_quantity,
        total_sales,
        total_profit
    FROM 
        SalesSummary
    WHERE 
        rank <= 5
),
ReturnedItems AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_value
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
ExtendedSales AS (
    SELECT 
        t.web_site_id,
        SUM(t.total_quantity) AS overall_quantity,
        SUM(t.total_sales) AS overall_sales,
        COALESCE(SUM(r.total_returns), 0) AS total_returns,
        COALESCE(SUM(r.total_return_value), 0) AS total_return_value
    FROM 
        TopWebsites t
    LEFT JOIN 
        ReturnedItems r ON t.web_site_id = r.wr_item_sk
    GROUP BY 
        t.web_site_id
)
SELECT 
    e.web_site_id,
    e.overall_quantity,
    e.overall_sales,
    e.total_returns,
    e.total_return_value,
    CASE 
        WHEN e.total_returns > 0 THEN (e.total_return_value / e.overall_sales) * 100
        ELSE NULL 
    END AS return_percentage
FROM 
    ExtendedSales e
ORDER BY 
    e.overall_sales DESC;
