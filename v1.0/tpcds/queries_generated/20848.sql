
WITH demographic_summary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(CASE WHEN cd_credit_rating = 'Unknown' THEN 1 ELSE 0 END) AS unknown_credit_count
    FROM customer_demographics
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_gender, cd_marital_status
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_discount_amt) AS total_discounts
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
inventory_summary AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_item_sk
),
returns_summary AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ss.total_sales,
    ss.total_orders,
    rs.total_returns,
    rs.total_return_amount,
    ds.total_purchase_estimate,
    ds.unknown_credit_count,
    CASE 
        WHEN ds.total_customers > 0 THEN ds.total_purchase_estimate / ds.total_customers
        ELSE 0 
    END AS avg_purchase_per_customer,
    CASE 
        WHEN ss.total_sales > 0 AND ss.total_orders > 0 THEN ss.total_sales / ss.total_orders
        ELSE 0 
    END AS avg_sales_per_order,
    (SELECT COUNT(*) FROM item WHERE i_current_price IS NULL) AS null_price_items,
    (SELECT COUNT(DISTINCT wp_web_page_sk) FROM web_page WHERE wp_creation_date_sk IS NOT NULL) AS created_pages,
    (SELECT COUNT(DISTINCT sr_ticket_number) FROM store_returns 
        WHERE sr_return_quantity IS NULL OR sr_return_quantity < 0) AS bizarre_returns
FROM demographic_summary ds
LEFT JOIN sales_summary ss ON ds.total_customers = ss.ws_bill_customer_sk
LEFT JOIN returns_summary rs ON ds.total_customers = rs.sr_customer_sk
GROUP BY ds.cd_gender, ds.cd_marital_status, ss.total_sales, ss.total_orders, rs.total_returns, rs.total_return_amount, ds.total_purchase_estimate, ds.unknown_credit_count
ORDER BY ds.cd_gender, ds.cd_marital_status;
