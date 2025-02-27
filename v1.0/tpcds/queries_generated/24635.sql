
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    JOIN 
        store_sales ON ws_item_sk = ss_item_sk
    GROUP BY 
        ss_store_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT 
        rs.ss_store_sk,
        rs.ws_item_sk,
        rs.total_sold
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_spent,
        MAX(CASE WHEN c.c_birth_year IS NOT NULL THEN c.c_birth_year END) AS max_birth_year
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
AddressStats AS (
    SELECT
        ca_county,
        COUNT(DISTINCT ca_address_sk) AS distinct_addresses,
        SUM(CASE WHEN ca_location_type = 'home' THEN 1 ELSE 0 END) AS home_count
    FROM 
        customer_address
    GROUP BY 
        ca_county
),
FinalReport AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(cs.total_orders, 0) AS order_count,
        COALESCE(cs.total_spent, 0) AS total_spending,
        COALESCE(as.distinct_addresses, 0) AS address_count,
        COALESCE(as.home_count, 0) AS home_count,
        tsi.ws_item_sk,
        tsi.total_sold
    FROM 
        CustomerStats cs
    FULL OUTER JOIN 
        AddressStats as ON cs.c_customer_id = as.ca_county
    RIGHT JOIN 
        TopSellingItems tsi ON cs.total_orders > 0
)
SELECT 
    f.c_customer_id,
    f.order_count,
    f.total_spending,
    f.address_count,
    f.home_count,
    f.ws_item_sk,
    f.total_sold
FROM 
    FinalReport f
WHERE 
    (f.order_count IS NULL AND f.total_spending IS NOT NULL)
    OR (f.address_count > 5 AND f.home_count < 2)
    OR (f.total_spending BETWEEN 100 AND 500)
ORDER BY 
    f.total_sold DESC, f.total_spending ASC
FETCH FIRST 10 ROWS ONLY;
