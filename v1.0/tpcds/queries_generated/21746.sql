
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_customer_sk ORDER BY ws_net_paid DESC) AS rnk
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
), 
CustomerCTE AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(s.ws_net_paid) AS total_spent,
        COUNT(s.ws_item_sk) AS total_items
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN SalesCTE AS s ON c.c_customer_sk = s.ws_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
TopCustomers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rnk
    FROM CustomerCTE
    WHERE total_spent IS NOT NULL
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_credit_rating,
    COALESCE(NULLIF(tc.total_spent, 0), 'No Purchases') AS formatted_spent,
    CASE 
        WHEN tc.rnk <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status,
    'Region: ' || COALESCE(NULLIF(w.w_country, ''), 'Unknown') AS customer_region
FROM TopCustomers AS tc
LEFT JOIN customer_address AS ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer AS c WHERE c.c_customer_id = tc.c_customer_id)
LEFT JOIN warehouse AS w ON w.w_warehouse_sk = (SELECT ws.ws_warehouse_sk FROM web_sales AS ws WHERE ws.ws_bill_customer_sk = tc.c_customer_id LIMIT 1)
WHERE tc.rnk <= 20 OR w.w_country IS NULL
ORDER BY tc.total_spent DESC, tc.c_customer_id
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
