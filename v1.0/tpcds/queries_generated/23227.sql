
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(cd.cd_dep_count, 0) AS dependents,
        COUNT(DISTINCT ws.web_site_sk) AS web_sites_visited
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating, cd.cd_dep_count
),
inventory_info AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand,
        MIN(inv.inv_date_sk) AS earliest_stock_date,
        MAX(inv.inv_date_sk) AS latest_stock_date
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    COUNT(DISTINCT rs.ws_item_sk) AS items_ranked,
    SUM(CASE WHEN rs.rank <= 5 THEN rs.total_quantity ELSE 0 END) AS top_sales_quantity,
    ii.total_on_hand,
    ii.earliest_stock_date,
    ii.latest_stock_date,
    CASE 
        WHEN ci.dependents > 3 THEN 'Large Family'
        WHEN ci.dependents BETWEEN 1 AND 3 THEN 'Small Family'
        ELSE 'Single'
    END AS family_size_category
FROM 
    customer_info ci
LEFT JOIN 
    ranked_sales rs ON ci.c_customer_sk = rs.ws_item_sk
LEFT JOIN 
    inventory_info ii ON rs.ws_item_sk = ii.inv_item_sk
GROUP BY 
    ci.c_customer_id, ci.cd_gender, ci.cd_marital_status, ci.cd_purchase_estimate, ci.dependents, ii.total_on_hand, ii.earliest_stock_date, ii.latest_stock_date
HAVING 
    SUM(CASE WHEN rs.total_quantity > 100 THEN 1 ELSE 0 END) >= 1
ORDER BY 
    top_sales_quantity DESC NULLS LAST;
