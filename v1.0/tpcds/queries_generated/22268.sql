
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.web_name, 
        ws.ws_sold_date_sk, 
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name, ws.ws_sold_date_sk
), SalesDetails AS (
    SELECT 
        rs.web_name,
        COUNT(DISTINCT rs.ws_sold_date_sk) AS active_days,
        AVG(rs.total_sales) AS avg_daily_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        rs.web_name
), StoreSales AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
), CombinedSales AS (
    SELECT 
        d.d_month_seq,
        sd.web_name,
        sd.active_days,
        sd.avg_daily_sales,
        COALESCE(ss.total_net_profit, 0) AS store_net_profit
    FROM 
        SalesDetails sd
    LEFT JOIN 
        StoreSales ss ON sd.web_name = (SELECT w.web_name FROM web_site w WHERE w.web_site_sk = sd.web_name)
    JOIN 
        date_dim d ON d.d_date_sk IN (SELECT s.ss_sold_date_sk FROM store_sales s)
    WHERE 
        d.d_month_seq BETWEEN 1 AND 12
)
SELECT 
    web_name,
    SUM(active_days) AS total_active_days,
    AVG(avg_daily_sales) AS overall_avg_daily_sales,
    SUM(store_net_profit) AS total_store_net_profit,
    (CASE 
        WHEN SUM(store_net_profit) > 0 THEN 'Profitable' 
        ELSE 'Not Profitable' 
    END) AS profit_status
FROM 
    CombinedSales
GROUP BY 
    web_name
ORDER BY 
    total_active_days DESC, overall_avg_daily_sales DESC;
