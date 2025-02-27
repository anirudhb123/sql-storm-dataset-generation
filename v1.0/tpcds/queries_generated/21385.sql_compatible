
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_amt DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
TopReturns AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        COALESCE(SUM(sr.return_qty), 0) AS total_returned,
        COALESCE(SUM(sr.return_amt), 0) AS total_return_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM 
        item
    LEFT JOIN 
        (SELECT 
            sr_item_sk, 
            SUM(sr_return_quantity) AS return_qty, 
            SUM(sr_return_amt) AS return_amt,
            COUNT(sr_ticket_number) AS ticket_count
        FROM 
            store_returns
        WHERE 
            sr_item_sk IS NOT NULL
        GROUP BY 
            sr_item_sk) AS sr ON item.i_item_sk = sr.sr_item_sk
    WHERE 
        item.i_current_price > 0
    GROUP BY 
        item.i_item_sk, item.i_item_id
),
HighValueItems AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        item.i_item_desc,
        item.i_current_price,
        CASE 
            WHEN TRIM(item.i_item_desc) = '' THEN 'Description is empty'
            ELSE 'Description exists'
        END AS desc_status
    FROM 
        item
    WHERE 
        item.i_current_price > (SELECT AVG(i_current_price) FROM item) 
        AND item.i_item_sk NOT IN (SELECT sr_item_sk FROM store_returns WHERE sr_return_quantity > 5)
),
FinalAS AS (
    SELECT 
        hvi.i_item_id,
        hvi.i_item_desc,
        hvi.i_current_price,
        tr.total_returned,
        tr.total_return_amount,
        (CASE 
            WHEN tr.return_count IS NULL THEN 'No returns'
            ELSE CONCAT(tr.return_count, ' returns')
        END) AS return_message,
        hvi.desc_status
    FROM 
        HighValueItems hvi
    LEFT JOIN 
        TopReturns tr ON hvi.i_item_sk = tr.i_item_sk
)
SELECT 
    fa.*,
    (SELECT COUNT(*) 
     FROM customer_address ca 
     WHERE ca.ca_country IS NULL) AS null_ca_country_count,
    (SELECT AVG(cc.cc_tax_percentage) 
     FROM call_center cc 
     WHERE cc.cc_closed_date_sk IS NOT NULL) AS avg_closed_cc_tax
FROM 
    FinalAS fa
ORDER BY 
    fa.i_item_id;
