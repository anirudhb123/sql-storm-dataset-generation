
WITH RankedSales AS (
    SELECT 
        s_store_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s_store_sk, ss_item_sk
),
FrequentReasons AS (
    SELECT 
        cr_reason_sk,
        COUNT(cr_return_quantity) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_reason_sk
    HAVING 
        COUNT(cr_return_quantity) > 10
),
CustomerStats AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        MAX(cd_purchase_estimate) AS max_estimate,
        COUNT(DISTINCT c_email_address) AS unique_emails
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c_customer_sk, cd_gender
),
SalesInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand,
        COUNT(DISTINCT ws_sold_date_sk) AS sales_days
    FROM 
        inventory inv
    LEFT JOIN 
        web_sales ws ON inv.inv_item_sk = ws.ws_item_sk
    GROUP BY 
        inv.inv_item_sk
    HAVING 
        COUNT(DISTINCT ws_sold_date_sk) > 0
)
SELECT 
    cs.c_customer_sk,
    cs.max_estimate,
    rs.s_total_sales,
    CASE 
        WHEN rs.s_total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status,
    COALESCE(FR.return_count, 0) AS return_count,
    si.total_on_hand,
    si.sales_days,
    cd.cd_gender
FROM 
    CustomerStats cs
LEFT JOIN 
    RankedSales rs ON cs.c_customer_sk = rs.s_store_sk
LEFT JOIN 
    FrequentReasons FR ON rs.s_item_sk = FR.cr_reason_sk
JOIN 
    SalesInventory si ON rs.ss_item_sk = si.inv_item_sk
JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    (cs.max_estimate BETWEEN (SELECT ib_lower_bound FROM income_band WHERE ib_income_band_sk = 1) 
     AND (SELECT ib_upper_bound FROM income_band WHERE ib_income_band_sk = 5))
    OR (cd_gender IS NULL AND (rs.s_total_sales > 10000 OR si.total_on_hand > 0))
ORDER BY 
    sales_status DESC, cs.max_estimate DESC;
