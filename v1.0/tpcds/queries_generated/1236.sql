
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
StoreSalesSummary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
ReturnsSummary AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_amt) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
SalesAndReturns AS (
    SELECT 
        s.s_store_sk,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returns, 0)) AS net_sales
    FROM 
        store s
    LEFT JOIN 
        StoreSalesSummary ss ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN 
        ReturnsSummary rs ON s.s_store_sk = rs.sr_store_sk
)
SELECT 
    s.s_store_sk,
    SUM(SALES.total_sales) AS total_sales,
    SUM(SALES.total_returns) AS total_returns,
    SUM(SALES.net_sales) AS net_sales,
    MAX(CASE WHEN RANKED.purchase_rank = 1 THEN CONCAT(c_first_name, ' ', c_last_name) END) AS top_customer
FROM 
    SalesAndReturns SALES
LEFT JOIN 
    RankedCustomers RANKED ON RANKED.c_customer_sk IN (
        SELECT c_customer_sk 
        FROM customer 
        WHERE c_current_addr_sk IS NOT NULL
    )
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = RANKED.c_customer_sk)
GROUP BY 
    s.s_store_sk
ORDER BY 
    net_sales DESC;
