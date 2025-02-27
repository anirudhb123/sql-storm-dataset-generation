
WITH aggregated_sales AS (
    SELECT 
        COALESCE(wc.cc_mkt_desc, 'Unknown') AS market_description,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS sales_count
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        call_center cc ON c.c_current_hdemo_sk = cc.cc_call_center_sk
    LEFT JOIN 
        web_site wc ON ws.ws_web_site_sk = wc.web_site_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2021-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2021-12-31'
        )
    GROUP BY 
        market_description
),
ranked_sales AS (
    SELECT 
        market_description,
        total_sales,
        total_discount,
        sales_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        aggregated_sales
)
SELECT 
    market_description,
    total_sales,
    total_discount,
    sales_count
FROM 
    ranked_sales
WHERE 
    sales_rank <= 10
ORDER BY 
    total_sales DESC;
