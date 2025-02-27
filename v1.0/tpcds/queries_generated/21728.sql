
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales
    WHERE
        ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT 
        customer.c_customer_id,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS avg_price,
        COUNT(ws_item_sk) AS item_count
    FROM 
        RankedSales
    JOIN 
        customer ON customer.c_customer_sk = RankedSales.ws_bill_customer_sk
    GROUP BY 
        customer.c_customer_id
),
HighValueCustomers AS (
    SELECT
        ss.c_customer_id,
        ss.total_quantity,
        ss.avg_price,
        CASE 
            WHEN ss.total_quantity > 100 THEN 'High'
            WHEN ss.total_quantity BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS customer_value
    FROM 
        SalesSummary ss
    WHERE
        ss.avg_price IS NOT NULL
),
ReturnData AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    hvc.c_customer_id,
    hvc.total_quantity,
    hvc.avg_price,
    COALESCE(rd.return_count, 0) AS return_count,
    CASE 
        WHEN hvc.customer_value = 'High' AND COALESCE(rd.return_count, 0) > 5 THEN 'Shopper with High Returns'
        WHEN hvc.customer_value = 'Medium' AND COALESCE(rd.return_count, 0) = 0 THEN 'Cautious Shopper'
        ELSE 'Regular'
    END AS shopper_category
FROM 
    HighValueCustomers hvc
LEFT OUTER JOIN 
    ReturnData rd ON hvc.c_customer_id = rd.sr_customer_sk
ORDER BY 
    hvc.total_quantity DESC,
    hvc.avg_price DESC;
