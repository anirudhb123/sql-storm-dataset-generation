
WITH RECURSIVE address_cities AS (
    SELECT DISTINCT ca_city, ca_state
    FROM customer_address
    WHERE ca_city IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(cd.cd_purchase_estimate, 0) DESC) AS purchase_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
    HAVING SUM(cs.cs_quantity) > (SELECT AVG(sales) FROM (SELECT SUM(cs_quantity) AS sales FROM catalog_sales GROUP BY cs_item_sk) AS avg_sales)
),
outer_sales AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.purchase_estimate,
        COALESCE(ss.total_quantity, 0) AS item_quantity,
        COALESCE(ss.total_sales, 0.00) AS item_sales
    FROM customer_info ci
    LEFT JOIN sales_summary ss ON ci.c_customer_sk = 
        (SELECT cs_bill_customer_sk 
         FROM web_sales 
         WHERE ws_item_sk = ANY (SELECT cs_item_sk 
                                  FROM catalog_sales 
                                  WHERE cs_quantity > 10)
         LIMIT 1)  -- Correlated subquery returns only one matching bill customer
),
final_summary AS (
    SELECT 
        oc.ca_city,
        oc.ca_state,
        SUM(os.item_quantity) AS total_item_quantities,
        SUM(os.item_sales) AS total_sales_value,
        COUNT(DISTINCT os.c_customer_sk) AS unique_customers
    FROM outer_sales os
    JOIN address_cities oc ON os.c_customer_sk IS NOT NULL
    GROUP BY ROLLUP(oc.ca_city, oc.ca_state)
)
SELECT 
    city,
    state,
    total_item_quantities,
    total_sales_value,
    unique_customers,
    CASE 
        WHEN total_sales_value IS NULL THEN 'No Sales'
        WHEN total_sales_value >= 10000 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS sales_category
FROM final_summary
WHERE unique_customers > 5
ORDER BY total_sales_value DESC NULLS LAST;
