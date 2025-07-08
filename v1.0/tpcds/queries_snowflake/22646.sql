
WITH RankedCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        RANK() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS GenderRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ActiveWebSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS TotalNetProfit 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
    GROUP BY 
        ws_bill_customer_sk
),
StoreSalesSummary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS TotalPaid,
        COUNT(DISTINCT ss_ticket_number) AS TotalTransactions
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
ReturnStats AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS TotalReturned,
        COUNT(DISTINCT cr_order_number) AS TotalReturns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
)

SELECT 
    rc.c_first_name, 
    rc.c_last_name, 
    rc.cd_gender, 
    rc.cd_marital_status,
    aw.TotalNetProfit,
    sss.TotalPaid,
    COALESCE(rs.TotalReturned, 0) AS TotalReturns
FROM 
    RankedCustomers rc
LEFT JOIN 
    ActiveWebSales aw ON rc.c_customer_sk = aw.ws_bill_customer_sk
LEFT JOIN 
    StoreSalesSummary sss ON sss.ss_store_sk = (SELECT ss_store_sk FROM store WHERE s_store_name LIKE '%Discount%') 
LEFT JOIN 
    ReturnStats rs ON rc.c_customer_sk = rs.cr_returning_customer_sk
WHERE 
    rc.GenderRank <= 10 AND
    (rc.cd_marital_status = 'M' OR rc.cd_marital_status IS NULL) AND
    (aw.TotalNetProfit > 1000 OR aw.TotalNetProfit IS NULL) 
ORDER BY 
    COALESCE(aw.TotalNetProfit, 0) DESC,
    rc.c_first_name ASC;
