
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_returns
    FROM 
        web_returns wr
    JOIN 
        web_sales ws ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    GROUP BY 
        wr_returning_customer_sk
),
AverageReturns AS (
    SELECT 
        AVG(total_returns) AS average_return
    FROM 
        CustomerReturns
),
SalesAndReturns AS (
    SELECT 
        tw.web_site_id,
        tw.total_sales,
        ar.average_return
    FROM 
        TopWebsites tw
    CROSS JOIN 
        AverageReturns ar
)
SELECT 
    s.web_site_id,
    s.total_sales,
    s.average_return,
    CASE 
        WHEN total_sales > average_return THEN 'Profitable' 
        ELSE 'Unprofitable' 
    END AS profitability_status
FROM 
    SalesAndReturns s;
