
WITH customer_returns AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(wr_return_quantity), 0) AS web_return_qty,
        COALESCE(SUM(sr_return_quantity), 0) AS store_return_qty,
        COUNT(DISTINCT CASE 
            WHEN wr_order_number IS NOT NULL THEN wr_order_number 
            END) AS web_return_count,
        COUNT(DISTINCT CASE 
            WHEN sr_ticket_number IS NOT NULL THEN sr_ticket_number 
            END) AS store_return_count
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr_wr_returning_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer_address ca ON ca.ca_address_sk IN (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_current_cdemo_sk = cd.cd_demo_sk)
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cr.web_return_qty,
        cr.store_return_qty,
        cr.web_return_count,
        cr.store_return_count,
        CASE 
            WHEN cr.web_return_qty + cr.store_return_qty > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        customer c
    JOIN 
        customer_returns cr ON c.c_customer_id = cr.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    c_info.*,
    ROW_NUMBER() OVER (PARTITION BY c_info.cd_gender ORDER BY c_info.web_return_count DESC) AS gender_rank
FROM 
    customer_info c_info
WHERE 
    (c_info.web_return_qty > 5 OR c_info.store_return_qty > 5)
    AND c_info.return_status = 'Returned'
ORDER BY 
    c_info.cd_gender, c_info.web_return_qty DESC;
