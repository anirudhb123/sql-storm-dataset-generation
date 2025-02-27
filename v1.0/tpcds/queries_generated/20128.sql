
WITH RankedReturns AS (
    SELECT 
        CASE 
            WHEN wr_returned_date_sk IS NOT NULL THEN 'Web'
            WHEN sr_returned_date_sk IS NOT NULL THEN 'Store'
            ELSE 'Unknown'
        END AS Return_Source,
        COALESCE(ws_bill_customer_sk, ss_customer_sk) AS Customer_Sk,
        COALESCE(wr_return_quantity, sr_return_quantity) AS Return_Quantity,
        COALESCE(wr_return_amt, sr_return_amt) AS Return_Amt,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(ws_bill_customer_sk, ss_customer_sk) ORDER BY COALESCE(wr_returned_date_sk, sr_returned_date_sk) DESC) AS Rank
    FROM 
        web_returns wr
    FULL OUTER JOIN 
        store_returns sr ON wr_item_sk = sr_item_sk AND wr_return_number = sr_ticket_number 
    LEFT JOIN 
        web_sales ws ON wr_item_sk = ws.ws_item_sk AND wr_order_number = ws.ws_order_number
    LEFT JOIN 
        store_sales ss ON sr_item_sk = ss.ss_item_sk AND sr_ticket_number = ss.ss_ticket_number
), AggregateReturns AS (
    SELECT 
        Return_Source,
        Customer_Sk,
        SUM(Return_Quantity) AS Total_Return_Quantity,
        SUM(Return_Amt) AS Total_Return_Amt
    FROM 
        RankedReturns
    WHERE 
        Rank <= 10
    GROUP BY 
        Return_Source, Customer_Sk
)
SELECT 
    ar.Return_Source,
    ar.Customer_Sk,
    ar.Total_Return_Quantity,
    ar.Total_Return_Amt,
    COALESCE(cd_demo_sk, 0) AS Demo_Sk,
    CASE 
        WHEN ar.Total_Return_Amt > 1000 THEN 'High'
        WHEN ar.Total_Return_Amt BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS Return_Severity
FROM 
    AggregateReturns ar
LEFT JOIN 
    customer c ON ar.Customer_Sk = c.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ar.Total_Return_Quantity IS NOT NULL
    AND (c.c_birth_year IS NULL OR c.c_birth_year < 1970) 
    OR (c.c_email_address LIKE '%@example.%' AND ar.Total_Return_Amt IS NOT NULL)
ORDER BY 
    ar.Return_Source, ar.Total_Return_Amt DESC
FETCH FIRST 100 ROWS ONLY;
