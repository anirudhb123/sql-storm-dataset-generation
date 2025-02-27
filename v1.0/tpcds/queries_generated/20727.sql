
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
RecentReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.return_item_sk,
        sr.returned_customer_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.return_tax,
        ROW_NUMBER() OVER (PARTITION BY sr.returned_customer_sk ORDER BY sr.returned_date_sk DESC) AS return_rank
    FROM 
        store_returns sr
),
CombinedData AS (
    SELECT
        h.customer_id,
        h.total_spent,
        r.return_amount,
        r.return_quantity,
        COALESCE(r.returned_date_sk, '1970-01-01') AS return_date,
        CASE 
            WHEN r.return_quantity IS NULL THEN 'No Returns'
            ELSE 'Returned'
        END AS return_status,
        CONCAT(h.first_name, ' ', h.last_name) AS full_name
    FROM 
        HighValueCustomers h
    LEFT JOIN 
        (SELECT 
            rr.returned_customer_sk, 
            SUM(rr.return_amt) AS return_amount, 
            SUM(rr.return_quantity) AS return_quantity
         FROM 
            RecentReturns rr
         WHERE 
            rr.return_rank <= 5
         GROUP BY 
            rr.returned_customer_sk) r ON h.c_customer_sk = r.returned_customer_sk
)
SELECT 
    cd.ca_city, 
    COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
    AVG(cd.total_spent) AS avg_spent,
    SUM(CASE WHEN cd.return_status = 'Returned' THEN 1 ELSE 0 END) AS returns_count,
    STRING_AGG(cd.full_name, ', ') AS top_customers
FROM 
    CombinedData cd
JOIN 
    customer_address ca ON cd.c_customer_sk = ca.ca_address_sk
WHERE 
    cd.total_spent IS NOT NULL
    AND cd.total_spent > (SELECT AVG(total_spent) FROM HighValueCustomers)
GROUP BY 
    ca.ca_city
ORDER BY 
    customer_count DESC
LIMIT 10;
