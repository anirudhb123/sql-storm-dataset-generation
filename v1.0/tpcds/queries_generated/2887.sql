
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit,
        MIN(ws.ws_ship_date_sk) AS first_ship_date,
        MAX(ws.ws_ship_date_sk) AS last_ship_date,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        dd.d_year >= 2020
    GROUP BY 
        ws.web_site_id
), customer_stats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        dd.d_year,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            ELSE 
                CASE
                    WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
                    WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
                    ELSE 'High'
                END
        END AS purchase_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        date_dim dd ON c.c_first_sales_date_sk = dd.d_date_sk
), return_stats AS (
    SELECT 
        ws.ws_web_site_sk,
        COUNT(sr.sr_item_sk) AS total_returns,
        SUM(sr.sr_return_amt) as total_return_amount
    FROM 
        store_returns sr
    JOIN 
        web_sales ws ON sr.sr_item_sk = ws.ws_item_sk
    WHERE 
        sr.sr_returned_date_sk > 0
    GROUP BY 
        ws.ws_web_site_sk
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.order_count,
    sd.average_profit,
    cs.cd_gender,
    cs.purchase_band,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount
FROM 
    sales_data sd
LEFT JOIN 
    customer_stats cs ON cs.cd_purchase_estimate BETWEEN 1000 AND 5000
LEFT JOIN 
    return_stats rs ON rs.ws_web_site_sk = sd.web_site_id
WHERE 
    sd.sales_rank <= 5
ORDER BY 
    sd.total_sales DESC;
