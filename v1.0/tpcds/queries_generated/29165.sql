
WITH Address_City AS (
    SELECT DISTINCT ca_city AS city_name
    FROM customer_address
    WHERE ca_country = 'United States'
),

Customer_Summary AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_preferred_cust_flag = 'Y'
),

Item_Analysis AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        COUNT(*) AS sales_count,
        SUM(ws.ws_quantity) AS total_sales
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id, i.i_item_desc, i.i_current_price
    HAVING COUNT(*) > 100
),

Date_Analysis AS (
    SELECT
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_year
)

SELECT 
    cs.full_name,
    cs.city_name,
    ia.i_item_id,
    ia.i_item_desc,
    ia.total_sales,
    da.total_orders,
    da.total_revenue
FROM Customer_Summary cs
JOIN Address_City ac ON cs.city_name = ac.city_name
JOIN Item_Analysis ia ON ia.total_sales > 1000
JOIN Date_Analysis da ON da.total_orders > 50
ORDER BY da.total_revenue DESC, ia.total_sales DESC;
