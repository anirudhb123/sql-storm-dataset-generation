
WITH RankedReturns AS (
    SELECT
        cr.returning_customer_sk,
        cr.returning_cdemo_sk,
        cr.return_item_sk,
        RANK() OVER(PARTITION BY cr.returning_customer_sk ORDER BY cr.return_quantity DESC) AS return_rank
    FROM 
        catalog_returns cr
),
MaxReturns AS (
    SELECT 
        returning_customer_sk, 
        MAX(return_rank) AS max_return_rank
    FROM 
        RankedReturns
    GROUP BY 
        returning_customer_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(cs.cs_quantity) AS total_catalog_quantity,
        SUM(ws.ws_quantity) AS total_web_quantity,
        COALESCE(SUM(cr.return_quantity), 0) AS total_returns,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        RankedReturns rr ON rr.returning_customer_sk = c.c_customer_sk
    LEFT JOIN 
        MaxReturns mr ON mr.returning_customer_sk = c.c_customer_sk AND rr.return_rank = mr.max_return_rank
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.total_catalog_quantity,
    cs.total_web_quantity,
    cs.total_returns,
    CASE 
        WHEN cs.total_returns > 5 THEN 'High Return'
        WHEN cs.total_returns > 0 THEN 'Moderate Return'
        ELSE 'No Return'
    END AS return_category,
    CASE 
        WHEN cs.total_catalog_quantity > cs.total_web_quantity THEN 'Catalog Dominant'
        ELSE 'Web Dominant'
    END AS sales_channel,
    (SELECT COUNT(*) FROM customer c2 WHERE c2.c_birth_year < 1980 AND c2.c_gender = 'F') AS female_age_count
FROM 
    CustomerStats cs
WHERE 
    cs.max_purchase_estimate > (
        SELECT AVG(cd_purchase_estimate) 
        FROM customer_demographics 
        WHERE cd_gender = 'M' 
        AND cd_purchase_estimate IS NOT NULL
    ) 
AND (cs.total_catalog_quantity + cs.total_web_quantity) > 100 
ORDER BY 
    cs.total_returns DESC, 
    cs.last_name ASC NULLS LAST;
