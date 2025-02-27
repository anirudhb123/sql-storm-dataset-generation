
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk 
    WHERE 
        dd.d_year BETWEEN 2022 AND 2023
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
),
AggregatedReturns AS (
    SELECT 
        wr.w_web_site_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_value
    FROM 
        web_returns wr
    JOIN 
        web_sales ws ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20231231
    GROUP BY 
        wr.w_web_site_sk
)
SELECT 
    rs.web_site_sk,
    rs.total_quantity,
    rs.total_sales,
    ar.total_returns,
    ar.total_return_value,
    (rs.total_sales - ar.total_return_value) AS net_sales
FROM 
    RankedSales rs
LEFT JOIN 
    AggregatedReturns ar ON rs.web_site_sk = ar.w_web_site_sk
WHERE 
    rs.rank <= 5
ORDER BY 
    rs.total_sales DESC;
