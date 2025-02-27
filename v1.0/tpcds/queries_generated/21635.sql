
WITH RankedReturns AS (
    SELECT 
        sr_item_sk, 
        COUNT(*) AS return_count,
        SUM(sr_return_quantity) AS total_returned_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM store_returns
    GROUP BY sr_item_sk
), 
FilteredReturns AS (
    SELECT 
        rr.*, 
        COALESCE(i.i_item_desc, 'Description Not Available') AS item_description,
        CASE 
            WHEN rr.total_returned_quantity > 10 THEN 'High Return'
            WHEN rr.total_returned_quantity BETWEEN 5 AND 10 THEN 'Moderate Return'
            ELSE 'Low Return'
        END AS return_category
    FROM RankedReturns rr
    LEFT JOIN item i ON rr.sr_item_sk = i.i_item_sk
    WHERE rr.return_count > 1
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        MAX(COALESCE(s.s_store_name, 'Unknown')) as store_name
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY c.c_customer_sk
), 
ReturnDetails AS (
    SELECT 
        fr.item_description,
        fr.return_category,
        cs.total_returns,
        ROW_NUMBER() OVER (PARTITION BY fr.return_category ORDER BY cs.total_returns DESC) AS category_rank
    FROM FilteredReturns fr
    JOIN CustomerStats cs ON cs.total_returns > 0
)
SELECT 
    rd.item_description,
    rd.return_category,
    rd.total_returns,
    CASE 
        WHEN rd.category_rank = 1 THEN 'Top in Category'
        ELSE 'Other'
    END AS category_status
FROM ReturnDetails rd
WHERE rd.return_category IS NOT NULL
ORDER BY rd.return_category, rd.total_returns DESC;
