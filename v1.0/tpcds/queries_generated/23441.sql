
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk, 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.web_site_sk, ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CD.cd_credit_rating,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count,
        SUM(CASE WHEN cd.cd_dep_count IS NULL THEN 0 ELSE cd.cd_dep_count END) AS total_dependents
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_preferred_cust_flag IS NOT NULL -- Filtering out customers with no preference flag
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
), 
inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        SUM(CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 0 ELSE inv.inv_quantity_on_hand END) AS total_quantity,
        CASE 
            WHEN SUM(inv.inv_quantity_on_hand) IS NULL THEN 'No Stock'
            WHEN SUM(inv.inv_quantity_on_hand) = 0 THEN 'Out of Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
), 
store_sales_summary AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sales_price > 0
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    rs.web_site_sk,
    rs.ws_item_sk,
    rs.total_sales,
    is.total_quantity,
    is.stock_status,
    sss.total_net_profit,
    sss.total_transactions
FROM 
    customer_info ci
LEFT JOIN 
    ranked_sales rs ON ci.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics) 
    AND rs.sales_rank <= 5
LEFT JOIN 
    inventory_status is ON rs.ws_item_sk = is.inv_item_sk
LEFT JOIN 
    store_sales_summary sss ON rs.ws_item_sk = sss.ss_item_sk
WHERE 
    ci.address_count > 2
    OR (ci.cd_marital_status = 'M' AND ci.total_dependents > 3)
ORDER BY 
    ci.c_customer_id, total_sales DESC, total_net_profit ASC;
