
WITH RECURSIVE sales_data AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_sold,
        SUM(ss_net_paid) AS total_revenue,
        RANK() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) as rank_revenue
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
    HAVING 
        SUM(ss_net_paid) > 1000
),
top_items AS (
    SELECT 
        i_item_id,
        i_product_name,
        sd.total_sold,
        sd.total_revenue
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ss_item_sk = i.i_item_sk
    WHERE 
        sd.rank_revenue <= 10
),
customer_summary AS (
    SELECT 
        cd_demo_sk,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        SUM(COALESCE(cd_purchase_estimate, 0)) AS total_purchase_estimate
    FROM 
        customer_demographics cd
    INNER JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk
),
address_info AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_state
)
SELECT 
    ti.i_product_name,
    ti.total_sold,
    ti.total_revenue,
    cs.customer_count,
    cs.total_purchase_estimate,
    ai.unique_addresses
FROM 
    top_items ti
LEFT JOIN 
    customer_summary cs ON cs.cd_demo_sk = ti.total_sold % 10  -- Arbitrary join for illustration
LEFT JOIN 
    address_info ai ON ai.ca_state = 'NY'  -- Fixed condition as example
WHERE 
    ti.total_revenue > (SELECT AVG(total_revenue) FROM sales_data)
ORDER BY 
    ti.total_revenue DESC
LIMIT 50;
