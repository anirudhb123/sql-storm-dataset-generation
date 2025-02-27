
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IS NOT NULL
),
TotalSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        rc.c_customer_sk,
        COALESCE(ts.total_sales, 0) AS total_sales,
        ts.order_count
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        TotalSales ts ON rc.c_customer_sk = ts.ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_sales,
    CASE 
        WHEN cs.total_sales = 0 THEN 'No Sales'
        WHEN cs.total_sales BETWEEN 1 AND 100 THEN 'Low Sales'
        WHEN cs.total_sales BETWEEN 101 AND 1000 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category,
    (SELECT COUNT(*) 
     FROM store s 
     WHERE s.s_closed_date_sk IS NULL
       AND s.s_zip = (SELECT ca_zip 
                      FROM customer_address 
                      WHERE ca_address_sk = (SELECT c.c_current_addr_sk 
                                              FROM customer c 
                                              WHERE c.c_customer_sk = cs.c_customer_sk)
                     )
    ) AS active_stores_in_zip,
    (SELECT STRING_AGG(p.p_promo_name, ', ')
     FROM promotion p 
     WHERE EXISTS (
         SELECT 1 
         FROM web_sales ws 
         WHERE ws.ws_bill_customer_sk = cs.c_customer_sk 
           AND ws.ws_promo_sk = p.p_promo_sk
     )
    ) AS applicable_promotions
FROM 
    CustomerSales cs
WHERE 
    cs.rn <= 10
ORDER BY 
    cs.total_sales DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
