
WITH normalized_income AS (
    SELECT
        hd_demo_sk,
        CASE 
            WHEN ib_lower_bound IS NOT NULL AND ib_upper_bound IS NOT NULL 
            THEN CONCAT('Income Band: $', ib_lower_bound, ' - $', ib_upper_bound)
            ELSE 'Unclassified'
        END AS income_band
    FROM household_demographics h
    LEFT JOIN income_band i ON h.hd_income_band_sk = i.ib_income_band_sk
),
recent_orders AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        ws_bill_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk, ws_bill_customer_sk
),
return_stats AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr_returning_customer_sk) AS unique_returning_customers
    FROM web_returns
    GROUP BY wr_item_sk
),
address_stats AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca_city
),
high_value_customers AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        income_band
    FROM customer_demographics cd
    JOIN normalized_income ni ON cd.cd_demo_sk = ni.hd_demo_sk
    WHERE cd_purchase_estimate > 10000
        AND cd_gender IS NOT NULL
        AND cd_marital_status IN ('M', 'S')
),
qualified_returns AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_returns,
        rs.total_return_amount,
        AVG(rs.total_return_amount) OVER (PARTITION BY rs.ws_item_sk) AS avg_return_amount
    FROM return_stats rs
    JOIN recent_orders ro ON rs.ws_item_sk = ro.ws_item_sk
    WHERE ro.rn = 1 AND rs.total_return_amount > (SELECT AVG(total_return_amount) FROM return_stats)
),
inventory_status AS (
    SELECT 
        inv_item_sk,
        MAX(inv_quantity_on_hand) AS max_quantity,
        MIN(inv_quantity_on_hand) AS min_quantity,
        (MAX(inv_quantity_on_hand) - MIN(inv_quantity_on_hand)) AS inventory_variance
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT 
    ci.c_full_name,
    ci.income_band,
    ci.total_quantity,
    ki.max_quantity,
    ki.min_quantity,
    ki.inventory_variance,
    ca.customer_count
FROM (
    SELECT 
        high_value_customers.cd_demo_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS c_full_name,
        high_value_customers.income_band,
        ro.total_quantity
    FROM high_value_customers
    JOIN recent_orders ro ON high_value_customers.cd_demo_sk = ro.ws_bill_customer_sk
    JOIN customer c ON ro.ws_bill_customer_sk = c.c_customer_sk
) ci
JOIN inventory_status ki ON ci.cd_demo_sk = ki.inv_item_sk
JOIN address_stats ca ON ca.customer_count > 10
WHERE ki.inventory_variance > 5
ORDER BY ci.total_quantity DESC, ca.customer_count DESC
LIMIT 50;
