
WITH RankedOrders AS (
    SELECT
        ws_bill_customer_sk,
        ws_item_sk,
        ws_sold_date_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_quantity > 0
),
CustomerAggregate AS (
    SELECT
        c.c_customer_sk,
        SUM(CASE WHEN d.d_dow IN (0, 6) THEN wo.ws_sales_price ELSE 0 END) AS weekend_spending,
        AVG(COALESCE(wo.ws_sales_price, 0)) AS average_weekday_spending,
        COUNT(DISTINCT wo.ws_item_sk) AS distinct_items_purchased
    FROM
        customer AS c
    LEFT JOIN
        web_sales AS wo ON c.c_customer_sk = wo.ws_bill_customer_sk
    LEFT JOIN
        date_dim AS d ON wo.ws_sold_date_sk = d.d_date_sk
    WHERE
        wo.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 90 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        ca.c_customer_sk AS c_customer_id,
        ca.c_first_name,
        ca.c_last_name,
        ca.c_email_address,
        ca.c_birth_country,
        ca_rank.weekend_spending,
        ca_rank.average_weekday_spending,
        ca_rank.distinct_items_purchased
    FROM 
        customer AS ca
    JOIN 
        CustomerAggregate AS ca_rank ON ca.c_customer_sk = ca_rank.c_customer_sk
    ORDER BY
        ca_rank.weekend_spending DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.c_email_address, 'No Email') AS email,
    (SELECT COUNT(*) FROM store_sales WHERE ss_customer_sk = tc.c_customer_id AND ss_sales_price > 100.00) AS high_value_store_transactions,
    (SELECT COUNT(*) FROM catalog_sales WHERE cs_bill_customer_sk = tc.c_customer_id AND cs_sales_price < 50.00) AS low_value_catalog_transactions
FROM 
    TopCustomers AS tc
WHERE 
    EXISTS (
        SELECT 1
        FROM customer_demographics AS cd
        WHERE cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = tc.c_customer_id)
        AND cd.cd_credit_rating IN ('Excellent', 'Good')
    )
OR 
    EXISTS (
        SELECT 1
        FROM inventory AS inv
        WHERE inv.inv_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = tc.c_customer_id)
        AND inv.inv_quantity_on_hand = 0
    );
