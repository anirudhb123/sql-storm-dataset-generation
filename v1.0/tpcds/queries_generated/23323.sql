
WITH ranked_sales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales cs
    LEFT JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE 
        AND (i.i_rec_end_date >= CURRENT_DATE OR i.i_rec_end_date IS NULL)
    GROUP BY 
        cs.cs_item_sk
),
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_sales
    FROM 
        ranked_sales sales
    JOIN 
        item ON sales.cs_item_sk = item.i_item_sk
    WHERE 
        sales.sales_rank <= 5
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'N/A' 
            ELSE CASE 
                WHEN cd.cd_purchase_estimate < 100 THEN 'Low'
                WHEN cd.cd_purchase_estimate BETWEEN 100 AND 1000 THEN 'Medium'
                ELSE 'High'
            END
        END AS purchase_estimate_band,
        ca.ca_city
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_info AS (
    SELECT 
        s.s_store_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY 
        s.s_store_name
),
final_data AS (
    SELECT 
        c.customer_id,
        ci.i_item_id,
        si.s_store_name,
        si.total_quantity_sold,
        si.total_net_profit
    FROM 
        customer_data c
    JOIN 
        top_items ci ON c.c_customer_id LIKE CONCAT('%', ci.i_item_id, '%')
    FULL OUTER JOIN 
        sales_info si ON si.total_quantity_sold IS NOT NULL OR si.total_net_profit IS NOT NULL
)
SELECT 
    final.customer_id,
    final.i_item_id,
    final.s_store_name,
    GREATEST(final.total_quantity_sold, 0) AS effective_quantity_sold,
    COALESCE(final.total_net_profit, 0.00) AS effective_net_profit,
    CASE 
        WHEN final.total_net_profit IS NOT NULL AND final.total_quantity_sold IS NULL THEN 'Returns Only'
        ELSE 'Sales or No Sales'
    END AS sales_status
FROM 
    final_data final
WHERE 
    final.customer_id IS NOT NULL OR final.i_item_id IS NOT NULL
ORDER BY 
    final.effective_net_profit DESC, final.effective_quantity_sold DESC;
