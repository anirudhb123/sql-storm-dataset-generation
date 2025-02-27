
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk, ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_sk,
        web_site_id,
        total_net_profit,
        total_orders
    FROM RankedSales
    WHERE rank <= 5
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        wd.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN TopWebSites wd ON ws.ws_web_site_sk = wd.web_site_sk
    GROUP BY wd.web_site_id
),
ReturnSum AS (
    SELECT 
        wr.web_site_id,
        COALESCE(SUM(wr.wr_return_quantity), 0) AS total_returns
    FROM web_returns wr
    JOIN TopWebSites wd ON wr.wr_web_page_sk = wd.web_site_sk
    GROUP BY wr.web_site_id
)
SELECT 
    wd.web_site_id,
    ss.total_quantity,
    ss.avg_sales_price,
    ss.order_count,
    rs.total_net_profit,
    rs.total_orders,
    COALESCE(rs.total_returns, 0) AS total_returns,
    ct.c_first_name,
    ct.c_last_name,
    ct.cd_gender,
    ct.cd_marital_status
FROM SalesSummary ss
INNER JOIN TopWebSites wd ON ss.web_site_id = wd.web_site_id
INNER JOIN CustomerDetails ct ON ct.hd_income_band_sk IS NOT NULL
LEFT JOIN ReturnSum rs ON wd.web_site_id = rs.web_site_id
WHERE (ct.cd_marital_status = 'M' OR ct.cd_gender = 'F')
ORDER BY ss.total_quantity DESC, rs.total_net_profit DESC;
