
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM store_sales
    GROUP BY ss_store_sk, ss_item_sk
), 
high_value_sales AS (
    SELECT 
        s.ss_store_sk,
        s.ss_item_sk,
        s.total_quantity,
        s.total_net_paid,
        CASE WHEN s.rank = 1 THEN 'Top Seller' ELSE 'Regular Seller' END AS seller_type,
        COALESCE(w.w_warehouse_name, 'Unknown Warehouse') AS warehouse_name
    FROM sales_summary s
    LEFT JOIN inventory i ON s.ss_item_sk = i.inv_item_sk
    LEFT JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE s.total_net_paid > (SELECT AVG(total_net_paid) FROM sales_summary)
), 
item_details AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        h.hd_buy_potential,
        i.i_formulation
    FROM item i
    JOIN household_demographics h ON i.i_item_sk = h.hd_demo_sk
    WHERE i.i_current_price IS NOT NULL
),
return_summary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS total_tickets
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    iv.ss_store_sk,
    iv.ss_item_sk,
    d.i_item_desc,
    iv.total_quantity,
    iv.total_net_paid,
    iv.warehouse_name,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    d.hd_buy_potential,
    d.i_current_price
FROM high_value_sales iv
JOIN item_details d ON iv.ss_item_sk = d.i_item_id
LEFT JOIN return_summary r ON iv.ss_item_sk = r.sr_item_sk
WHERE iv.seller_type = 'Top Seller' 
  AND (d.i_formulation IS NOT NULL OR iv.total_net_paid > 1000)
ORDER BY iv.ss_store_sk, iv.total_net_paid DESC;
