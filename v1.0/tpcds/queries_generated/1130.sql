
WITH sales_summary AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit,
        COUNT(DISTINCT CASE WHEN cd.cd_gender = 'M' THEN ws.ws_bill_customer_sk END) AS male_customers,
        COUNT(DISTINCT CASE WHEN cd.cd_gender = 'F' THEN ws.ws_bill_customer_sk END) AS female_customers
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.web_site_id
),
returns_data AS (
    SELECT 
        wr.wr_web_page_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(wr.wr_order_number) AS total_returns
    FROM web_returns wr
    GROUP BY wr.wr_web_page_sk
),
combined_data AS (
    SELECT 
        ss.web_site_id,
        ss.total_sales,
        ss.total_orders,
        ss.average_profit,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        COALESCE(rd.total_returns, 0) AS total_returns
    FROM sales_summary ss
    LEFT JOIN returns_data rd ON ss.web_site_id = rd.wr_web_page_sk
)
SELECT 
    cd.web_site_id,
    cd.total_sales,
    cd.total_orders,
    cd.average_profit,
    cd.total_return_amt,
    cd.total_returns,
    CASE 
        WHEN cd.total_sales > 0 THEN (cd.total_return_amt / cd.total_sales) * 100
        ELSE NULL
    END AS return_percentage,
    CASE
        WHEN cd.total_orders > 0 THEN cd.total_sales / cd.total_orders
        ELSE NULL
    END AS avg_order_value
FROM combined_data cd
ORDER BY cd.total_sales DESC
LIMIT 10;
