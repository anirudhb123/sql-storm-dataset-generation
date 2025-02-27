
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        cs_sales_price,
        cs_quantity,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY cs_sales_price DESC) AS sales_rank
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
CustomerReturnSummary AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT cr_order_number) AS total_returns
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
DetailedCustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CA.ca_city,
        CA.ca_state,
        COALESCE(r.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(p.promo_discount, 0) AS promo_discount
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address CA ON c.c_current_addr_sk = CA.ca_address_sk
    LEFT JOIN (
        SELECT 
            sr_customer_sk,
            SUM(sr_return_amt) AS total_returned_amount
        FROM store_returns
        GROUP BY sr_customer_sk
    ) AS r ON c.c_customer_sk = r.sr_customer_sk
    LEFT JOIN (
        SELECT 
            ws_bill_customer_sk,
            SUM(ws_ext_sales_price) * 0.15 AS promo_discount
        FROM web_sales
        WHERE ws_sold_date_sk > (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-15')
        GROUP BY ws_bill_customer_sk
    ) AS p ON c.c_customer_sk = p.ws_bill_customer_sk
),
FinalSalesSummary AS (
    SELECT 
        dci.c_first_name,
        dci.c_last_name,
        dci.ca_city,
        dci.ca_state,
        r.sales_rank,
        r.cs_sales_price,
        r.cs_quantity,
        dci.total_returned_quantity,
        dci.promo_discount
    FROM DetailedCustomerInfo dci
    JOIN RankedSales r ON dci.c_customer_sk = r.cs_item_sk
)
SELECT 
    fa.c_first_name,
    fa.c_last_name,
    fa.ca_city,
    fa.ca_state,
    CASE 
        WHEN fa.promo_discount > 0 THEN 'Discount Applied'
        ELSE 'No Discount'
    END AS discount_status,
    SUM(fa.cs_sales_price * fa.cs_quantity) AS total_sales,
    SUM(fa.total_returned_quantity) AS total_returns
FROM FinalSalesSummary fa
GROUP BY 
    fa.c_first_name, 
    fa.c_last_name, 
    fa.ca_city, 
    fa.ca_state, 
    fa.promo_discount
HAVING 
    SUM(fa.cs_sales_price * fa.cs_quantity) > 1000
ORDER BY 
    total_sales DESC;
