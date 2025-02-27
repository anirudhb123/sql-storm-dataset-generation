
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER(PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM
        web_sales ws
    INNER JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        d.d_moy BETWEEN 1 AND 6
    GROUP BY
        ws.web_site_sk,
        ws.web_site_id
),
TotalReturns AS (
    SELECT
        wr.wr_web_page_sk,
        COUNT(*) AS total_returns
    FROM
        web_returns wr
    INNER JOIN 
        web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE 
        wr.wr_returned_date_sk IN (
            SELECT 
                d.d_date_sk 
            FROM 
                date_dim d 
            WHERE 
                d.d_year = 2023 AND 
                d.d_moy BETWEEN 1 AND 6
        )
    GROUP BY
        wr.wr_web_page_sk
),
HighProfitSites AS (
    SELECT
        *
    FROM
        RankedSales
    WHERE 
        rank <= 5
)
SELECT 
    hps.web_site_id,
    hps.total_profit,
    COALESCE(tr.total_returns, 0) AS total_returns,
    CASE 
        WHEN COALESCE(tr.total_returns, 0) > 0 THEN 
            (hps.total_profit / NULLIF(tr.total_returns, 0))
        ELSE 
            hps.total_profit
    END AS profit_per_return
FROM 
    HighProfitSites hps
LEFT JOIN 
    TotalReturns tr ON hps.web_site_sk = tr.wr_web_page_sk
ORDER BY 
    profit_per_return DESC;
