
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS customer_rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
),
Returns AS (
    SELECT 
        wr_returned_date_sk,
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amt
    FROM web_returns
    GROUP BY wr_returned_date_sk, wr_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    s.ws_item_sk,
    s.ws_quantity,
    s.ws_sales_price,
    COALESCE(r.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(r.total_returned_amt, 0) AS total_returned_amt,
    (s.ws_sales_price * s.ws_quantity) - COALESCE(r.total_returned_amt, 0) AS net_sales_value,
    CASE
        WHEN (s.ws_sales_price IS NULL) THEN 'Price Not Available'
        ELSE NULL
    END AS price_null_logic,
    CASE 
        WHEN s.ws_quantity >= 5 THEN 'High Volume Sale'
        ELSE 'Normal Sale'
    END AS sale_category
FROM SalesCTE s
JOIN CustomerInfo ci ON s.ws_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_sk)
LEFT JOIN Returns r ON s.ws_item_sk = r.wr_item_sk AND s.ws_sold_date_sk = r.wr_returned_date_sk
WHERE s.rn = 1
ORDER BY net_sales_value DESC
LIMIT 100;
