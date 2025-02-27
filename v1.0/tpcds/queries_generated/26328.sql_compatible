
WITH RankedReturns AS (
    SELECT 
        wr.returned_date_sk,
        wr.return_time_sk,
        wr.item_sk,
        wr.return_quantity,
        wr.net_loss,
        ROW_NUMBER() OVER (PARTITION BY wr.returned_date_sk ORDER BY wr.net_loss DESC) AS rn
    FROM 
        web_returns wr
    WHERE 
        wr.returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
TopReturns AS (
    SELECT 
        rr.returned_date_sk,
        d.d_date AS return_date,
        SUM(rr.return_quantity) AS total_return_quantity,
        SUM(rr.net_loss) AS total_net_loss
    FROM 
        RankedReturns rr
    JOIN 
        date_dim d ON rr.returned_date_sk = d.d_date_sk
    WHERE 
        rr.rn <= 10
    GROUP BY 
        rr.returned_date_sk, d.d_date
),
DetailedInfo AS (
    SELECT 
        tr.return_date,
        tr.total_return_quantity,
        tr.total_net_loss,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        TopReturns tr
    JOIN 
        store s ON tr.return_date = s.s_sold_date_sk
    JOIN 
        customer_address ca ON s.s_store_sk = ca.ca_address_sk
)
SELECT 
    return_date,
    total_return_quantity,
    total_net_loss,
    COUNT(DISTINCT CONCAT(ca_city, ', ', ca_state, ', ', ca_country)) AS unique_locations
FROM 
    DetailedInfo
GROUP BY 
    return_date, total_return_quantity, total_net_loss
ORDER BY 
    return_date;
