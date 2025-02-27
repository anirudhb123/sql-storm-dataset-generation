
WITH relevant_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_sales_price - ws_ext_discount_amt) AS avg_net_price
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS catalog_quantity,
        SUM(cs.cs_net_paid) AS total_catalog_paid,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_paid) DESC) AS rank
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk
)
SELECT 
    ca.ca_address_sk,
    ca.ca_city,
    ca.ca_state,
    cs.rank,
    c.gender AS customer_gender,
    COALESCE(s.total_quantity, 0) AS total_web_quantity,
    COALESCE(s.total_net_paid, 0) AS total_web_sales,
    COALESCE(ss.catalog_quantity, 0) AS total_catalog_quantity,
    CASE 
        WHEN s.avg_net_price > 0 THEN 'Expensive' 
        ELSE 'Affordable' 
    END AS price_category
FROM 
    customer_address ca
LEFT JOIN 
    customer_data c ON ca.ca_address_sk = c.c_customer_sk
LEFT JOIN 
    relevant_sales s ON s.ws_item_sk = c.c_current_addr_sk
LEFT JOIN 
    sales_summary ss ON ss.cs_item_sk = c.c_current_addr_sk
WHERE 
    ca.ca_state IN ('CA', 'TX') 
    AND c.cd_marital_status IS NOT NULL
    AND (c.cd_purchase_estimate > 1000 OR c.cd_gender IS NULL)
ORDER BY 
    total_web_sales DESC,
    price_category ASC;
