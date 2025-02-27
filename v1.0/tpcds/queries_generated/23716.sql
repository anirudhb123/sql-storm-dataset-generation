
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank_sales,
        COALESCE(COUNT(ss.ss_ticket_number) FILTER (WHERE ss.ss_item_sk IS NOT NULL), 0) AS store_sale_count
    FROM 
        web_sales ws
    LEFT JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk AND ws.ws_order_number = ss.ss_ticket_number
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk, ws.ws_sales_price
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        CASE WHEN i.i_current_price > 100 THEN 'expensive' ELSE 'affordable' END AS price_category
    FROM 
        item i
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        hd.hd_income_band_sk IS NOT NULL
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    sd.item_desc,
    rs.rank_sales,
    rs.store_sale_count,
    CASE 
        WHEN rs.store_sale_count = 0 THEN 'No store sales'
        ELSE 'Some store sales'
    END AS sales_status,
    CASE 
        WHEN fd.price_category = 'expensive' THEN 'High Roller'
        ELSE 'Deal Finder'
    END AS customer_type
FROM 
    customer_info ci
JOIN 
    item_details fd ON fd.i_item_sk = (SELECT i.i_item_sk FROM ranked_sales rs WHERE rs.rank_sales = 1 AND rs.ws_order_number IN (SELECT ws.ws_order_number FROM web_sales ws WHERE ws.ws_bill_customer_sk = ci.c_customer_sk))
LEFT JOIN 
    ranked_sales rs ON rs.ws_item_sk = fd.i_item_sk
WHERE 
    ci.gender_rank <= 5
ORDER BY 
    ci.c_last_name, rs.rank_sales
FETCH FIRST 10 ROWS ONLY;
