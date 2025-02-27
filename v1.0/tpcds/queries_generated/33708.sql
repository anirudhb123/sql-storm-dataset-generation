
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 100 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS purchase_segment
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        ROW_NUMBER() OVER (ORDER BY i.i_current_price DESC) AS price_rank
    FROM 
        item i
    WHERE 
        i.i_current_price IS NOT NULL
),
returned_sales AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_net_loss) AS total_loss
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)

SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    its.i_item_desc,
    its.total_quantity,
    its.total_net_profit,
    itd.i_current_price,
    COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(rs.total_loss, 0) AS total_loss,
    CASE 
        WHEN rs.total_returned_quantity IS NULL THEN 'No Returns'
        WHEN rs.total_returned_quantity > 10 THEN 'High Returns'
        ELSE 'Normal Returns'
    END AS return_status
FROM 
    customer_info ci
JOIN 
    sales_summary its ON ci.c_customer_sk = its.ws_item_sk
JOIN 
    item_details itd ON its.ws_item_sk = itd.i_item_sk
LEFT JOIN 
    returned_sales rs ON its.ws_item_sk = rs.wr_item_sk
WHERE 
    itd.price_rank <= 100
ORDER BY 
    total_net_profit DESC, ci.c_last_name, ci.c_first_name;
