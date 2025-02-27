
WITH RECURSIVE return_summary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(sr_return_ticket_number) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rank
    FROM store_returns
    GROUP BY sr_item_sk
), 
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(CAST(NULLIF(i.i_current_price, 0) AS VARCHAR), 'Price Not Set') AS price_info,
        CASE 
            WHEN SUM(cs_ext_sales_price) IS NULL THEN 'No Sales Data'
            ELSE 'Sales Data Available'
        END AS sales_data_status
    FROM item i
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE i.i_rec_start_date < CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_current_price
), 
customer_analysis AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(CASE WHEN c.c_customer_id IS NOT NULL THEN 1 ELSE 0 END) AS active_customers,
        COUNT(DISTINCT CASE WHEN cx.hd_demo_sk IS NOT NULL AND cx.hd_income_band_sk IS NOT NULL THEN cx.hd_demo_sk END) AS demographic_count,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd.cd_purchase_estimate) AS min_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics cx ON cx.hd_demo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk
)

SELECT  
    d.d_date AS sales_date,
    i.i_product_name,
    coalesce(re.total_return_qty, 0) AS returned_quantity,
    coalesce(re.total_return_amt, 0) AS returned_amount,
    cu.active_customers,
    cu.demographic_count,
    cu.max_purchase_estimate,
    cu.min_purchase_estimate,
    CASE 
        WHEN re.rank = 1 THEN 'Top Return Item' 
        ELSE 'Regular Return Item' 
    END AS return_item_status
FROM return_summary re
FULL OUTER JOIN item_details i ON re.sr_item_sk = i.i_item_sk
JOIN date_dim d ON d.d_date_sk = EXTRACT(DAY FROM CURRENT_DATE) 
JOIN customer_analysis cu ON cu.cd_demo_sk = i.i_item_sk 
WHERE (COALESCE(i.price_info, 'Price Not Set') LIKE '%Not Set%' OR i.sales_data_status = 'No Sales Data')
AND d.d_year >= 2023
ORDER BY sales_date DESC, returned_amount DESC;
