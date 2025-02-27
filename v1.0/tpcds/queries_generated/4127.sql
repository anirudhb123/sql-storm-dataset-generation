
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
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
        wr.web_site_id,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        web_site wr ON rs.web_site_sk = wr.web_site_sk
    WHERE 
        rs.sales_rank <= 5
),
SalesSummary AS (
    SELECT 
        ws.web_site_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        TopWebSites tw ON ws.ws_web_site_sk = tw.web_site_id
    GROUP BY 
        ws.web_site_id
)
SELECT 
    tw.web_site_id,
    ss.total_orders,
    ss.total_quantity,
    ss.total_profit,
    COALESCE(NULLIF(ss.total_profit, 0), -1) AS profit_or_negative
FROM 
    TopWebSites tw
LEFT JOIN 
    SalesSummary ss ON tw.web_site_id = ss.web_site_id
ORDER BY 
    tw.total_sales DESC, tw.web_site_id;
