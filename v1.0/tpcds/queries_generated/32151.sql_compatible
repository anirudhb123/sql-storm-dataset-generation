
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid_inc_tax) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk, 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_net_paid_inc_tax) AS total_revenue
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY 
        cs_sold_date_sk, 
        cs_item_sk
),
aggregated_sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        SUM(ss.total_quantity_sold) AS total_quantity,
        SUM(ss.total_revenue) AS total_revenue
    FROM 
        sales_summary ss
    JOIN 
        item ON ss.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id, 
        item.i_product_name
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_credit_rating IS NOT NULL
),
final_summary AS (
    SELECT 
        ag.total_quantity,
        ag.total_revenue,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN ag.total_revenue > 1000 THEN 'High Value'
            WHEN ag.total_revenue BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        aggregated_sales ag
    LEFT JOIN 
        customer ON customer.c_first_shipto_date_sk IN (SELECT cd_demo_sk FROM customer_demographics)
    LEFT JOIN 
        customer_demographics cd ON customer.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    customer_value_segment,
    COUNT(*) AS number_of_sales,
    SUM(total_revenue) AS total_revenue_generated
FROM 
    final_summary
GROUP BY 
    customer_value_segment
ORDER BY 
    total_revenue_generated DESC;
