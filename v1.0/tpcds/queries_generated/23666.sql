
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as rank_sales,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
)

SELECT 
    ca.ca_address_id,
    cd.cd_gender,
    SUM(ss.ss_sales_price) AS total_store_sales,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    MAX(CASE WHEN ss.ss_sales_price IS NULL THEN 'Sales Price Unknown' ELSE 'Sales Price Known' END) AS sales_price_status,
    CASE 
        WHEN COUNT(DISTINCT wr_item_sk) > 0 THEN 'Online Returns Processed'
        ELSE 'No Online Returns'
    END AS online_return_status
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    (SELECT DISTINCT wr_item_sk FROM web_returns) wr ON ss.ss_item_sk = wr.wr_item_sk
JOIN 
    (SELECT ws_item_sk, COUNT(ws_order_number) AS order_count FROM ranked_sales WHERE rank_sales = 1 GROUP BY ws_item_sk HAVING COUNT(ws_order_number) > 1) top_items ON ss.ss_item_sk = top_items.ws_item_sk
GROUP BY 
    ca.ca_address_id, cd.cd_gender
HAVING 
    total_store_sales > (SELECT AVG(total_store_sales) FROM store_sales) * (CASE WHEN cd.cd_marital_status = 'M' THEN 1.2 ELSE 0.8 END)
ORDER BY 
    total_store_sales DESC, cd.cd_gender;
