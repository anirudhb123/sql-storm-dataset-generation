
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL 
        AND ws.ws_sales_price > 0
),
customer_counts AS (
    SELECT 
        c.c_customer_sk, 
        COUNT(DISTINCT CASE 
            WHEN cd.cd_gender = 'F' THEN c.c_customer_id 
            END) AS female_count,
        COUNT(DISTINCT CASE 
            WHEN cd.cd_gender = 'M' THEN c.c_customer_id 
            END) AS male_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
),
sales_summary AS (
    SELECT 
        sr.store_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_tickets
    FROM 
        store_returns sr
    WHERE 
        sr.sr_return_quantity > 0
    GROUP BY 
        sr.store_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COALESCE(ca.ca_city, 'Unknown') AS customer_city,
    SUM( CASE WHEN cs.cs_sales_price IS NOT NULL THEN cs.cs_sales_price ELSE 0 END ) AS total_catalog_sales,
    SUM( CASE WHEN wr.wr_return_amt IS NOT NULL THEN wr.wr_return_amt ELSE 0 END ) AS total_web_returns,
    AVG(CASE WHEN cs.net_profit IS NOT NULL THEN cs.net_profit ELSE NULL END) AS avg_net_profit,
    CASE 
        WHEN SUM(cs.cs_sales_price) > 1000 THEN 'High Value Customer'
        WHEN COUNT(DISTINCT cs.cs_order_number) > 5 THEN 'Frequent Customer'
        ELSE 'Occasional Customer'
    END AS customer_status
FROM 
    customer c
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN 
    web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN 
    customer_counts cc ON c.c_customer_sk = cc.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    sales_summary ss ON ss.store_sk = c.c_current_addr_sk
WHERE 
    c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city
HAVING 
    SUM(cs.cs_sales_price) > 500 OR COUNT(DISTINCT cs.cs_order_number) > 3
ORDER BY 
    total_catalog_sales DESC, customer_city;
