
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
aggregated_returns AS (
    SELECT 
        cr.cr_item_sk, 
        SUM(cr.cr_return_quantity) AS total_returned_qty,
        SUM(cr.cr_return_amt) AS total_return_amt
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
combined_data AS (
    SELECT 
        i.i_item_id,
        COALESCE(rs.sales_rank, 0) AS sales_rank,
        COALESCE(ar.total_returned_qty, 0) AS total_returned_qty,
        COALESCE(ar.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(rs.sales_rank, 0) = 1 THEN 'Best Seller'
            WHEN COALESCE(ar.total_returned_qty, 0) > 0 THEN 'Returned'
            ELSE 'Regular Item'
        END AS item_status
    FROM 
        item i
    LEFT JOIN 
        ranked_sales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        aggregated_returns ar ON i.i_item_sk = ar.cr_item_sk
)
SELECT 
    c.cm_cd_demo_sk, 
    c.c_first_name, 
    c.c_last_name, 
    c.c_email_address, 
    CD.cd_gender, 
    cd.cd_marital_status, 
    i.i_item_id,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    x.item_status
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    combined_data x ON x.i_item_id IN (
        SELECT 
            i.i_item_id 
        FROM 
            inventory inv
        WHERE 
            inv.inv_quantity_on_hand > 0
    )
WHERE 
    (cd.cd_purchase_estimate > 500 OR cd.cd_credit_rating = 'Excellent')
    AND c.c_first_name IS NOT NULL 
    AND c.c_last_name IS NOT NULL 
ORDER BY 
    cd.cd_purchase_estimate DESC, 
    c.c_last_name ASC
FETCH FIRST 100 ROWS ONLY;
