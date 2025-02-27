
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rnk
    FROM 
        web_sales ws
    WHERE
        ws.ws_net_paid IS NOT NULL
),
HighValueReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
    HAVING 
        SUM(sr_return_amt) > (
            SELECT 
                AVG(sr_return_amt) 
            FROM 
                store_returns
            WHERE 
                sr_return_amt IS NOT NULL
        )
),
AggregatedData AS (
    SELECT 
        i.i_item_id,
        COALESCE(rv.total_return_amt, 0) AS total_return_amt,
        SUM(CASE WHEN rs.rnk = 1 THEN rs.ws_net_paid ELSE 0 END) AS highest_sale_amt,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        item i
    LEFT JOIN 
        HighValueReturns rv ON i.i_item_sk = rv.sr_item_sk
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        i.i_item_id
),
FinalData AS (
    SELECT 
        ad.i_item_id,
        ad.total_return_amt,
        ad.highest_sale_amt,
        ad.unique_customers,
        CASE 
            WHEN ad.total_return_amt > 0 AND ad.highest_sale_amt IS NULL THEN 'No Sales But Returns'
            WHEN ad.unique_customers = 0 THEN 'No Customers'
            ELSE 'Active'
        END AS status,
        CASE 
            WHEN ad.total_return_amt > 0 THEN ROUND(ad.total_return_amt / NULLIF(ad.highest_sale_amt, 0), 2)
            ELSE NULL
        END AS return_to_sale_ratio
    FROM 
        AggregatedData ad
)
SELECT 
    f.i_item_id,
    f.total_return_amt,
    f.highest_sale_amt,
    f.unique_customers,
    f.status,
    f.return_to_sale_ratio
FROM 
    FinalData f
WHERE 
    f.status = 'Active'
    OR (f.status = 'No Customers' AND f.highest_sale_amt IS NOT NULL)
ORDER BY 
    f.return_to_sale_ratio DESC NULLS LAST, f.total_return_amt DESC;
