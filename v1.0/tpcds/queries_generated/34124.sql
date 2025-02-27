
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_count,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk 
), 
CustomerIncome AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ss.ticket_number) AS total_purchases
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_income_band_sk
),
AddressCounts AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
TopSellingItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        s.total_sales,
        s.sales_count
    FROM 
        SalesCTE AS s
    JOIN 
        item AS i ON s.ss_item_sk = i.i_item_sk
    WHERE 
        s.rank <= 10
),
OverallStats AS (
    SELECT
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(a.address_count) AS total_addresses,
        SUM(COALESCE(ci.total_purchases, 0)) AS total_purchases
    FROM 
        CustomerIncome ci
    JOIN 
        AddressCounts a ON a.ca_state IS NOT NULL
)

SELECT 
    tsi.i_item_id,
    tsi.total_sales,
    tsi.sales_count,
    os.total_customers,
    os.total_addresses,
    os.total_purchases
FROM 
    TopSellingItems tsi
CROSS JOIN 
    OverallStats os
ORDER BY 
    tsi.total_sales DESC;
