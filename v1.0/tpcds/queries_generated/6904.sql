
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        income_band ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq BETWEEN 1 AND 12
        AND ib.ib_income_band_sk IS NOT NULL
    GROUP BY 
        ws.web_site_id, ws.ws_sold_date_sk
), RankedSales AS (
    SELECT 
        web_site_id,
        ws_sold_date_sk,
        total_quantity,
        total_profit,
        total_orders,
        RANK() OVER (PARTITION BY web_site_id ORDER BY total_profit DESC) AS rank_profit
    FROM 
        SalesData
)

SELECT 
    rs.web_site_id,
    dd.d_date AS sale_date,
    rs.total_quantity,
    rs.total_profit,
    rs.total_orders
FROM 
    RankedSales rs
JOIN 
    date_dim dd ON rs.ws_sold_date_sk = dd.d_date_sk
WHERE 
    rs.rank_profit <= 5
ORDER BY 
    rs.web_site_id, rs.rank_profit;
