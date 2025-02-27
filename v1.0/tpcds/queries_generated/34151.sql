
WITH RECURSIVE cte_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
cte_customer AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rank_by_purchase
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
cte_returned AS (
    SELECT 
        sr_item_sk, 
        COUNT(sr_ticket_number) AS return_count, 
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
)
SELECT 
    itm.i_item_id,
    itm.i_item_desc,
    COALESCE(sales.total_sales, 0) AS total_sales,
    COALESCE(returned.return_count, 0) AS total_returns,
    COALESCE(returned.total_return_amt, 0) AS total_return_amt,
    cust.c_first_name, 
    cust.c_last_name, 
    cust.cd_gender,
    cust.cd_marital_status,
    RANK() OVER (ORDER BY COALESCE(sales.total_sales, 0) DESC) AS sales_rank,
    CASE 
        WHEN cust.cd_credit_rating IS NULL THEN 'Unknown'
        ELSE cust.cd_credit_rating 
    END AS credit_rating
FROM 
    item AS itm
LEFT JOIN 
    cte_sales AS sales ON itm.i_item_sk = sales.ws_item_sk AND sales.rn = 1
LEFT JOIN 
    cte_returned AS returned ON itm.i_item_sk = returned.sr_item_sk
JOIN 
    cte_customer AS cust ON cust.rank_by_purchase <= 5 AND 
    (cust.cd_marital_status = 'M' OR (cust.cd_gender = 'F' AND cust.cd_purchase_estimate > 1000))
WHERE 
    itm.i_current_price > (SELECT AVG(i_current_price) FROM item)
ORDER BY 
    total_sales DESC, 
    total_returns ASC;
