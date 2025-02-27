
WITH RankedReturns AS (
    SELECT 
        CASE 
            WHEN wr_returned_date_sk IS NOT NULL THEN 'Web' 
            ELSE 'Store' 
        END AS Return_Type,
        COALESCE(wr_order_number, sr_ticket_number) AS Order_Number,
        COALESCE(SUM(wr_return_quantity), 0) AS Total_Returned_Quantity,
        COALESCE(SUM(wr_return_amt), 0) AS Total_Returned_Amount,
        RANK() OVER (PARTITION BY COALESCE(wr_order_number, sr_ticket_number) ORDER BY COALESCE(SUM(wr_return_quantity), 0) DESC) AS Return_Rank
    FROM 
        web_returns wr 
    FULL OUTER JOIN 
        store_returns sr ON wr_order_number = sr_ticket_number
    GROUP BY 
        Return_Type, COALESCE(wr_order_number, sr_ticket_number)
),
TopReturns AS (
    SELECT 
        Return_Type, 
        Order_Number, 
        Total_Returned_Quantity, 
        Total_Returned_Amount
    FROM 
        RankedReturns
    WHERE 
        Return_Rank <= 10
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        SUM(COALESCE(ws.net_profit, 0)) AS Total_Profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000 
        AND cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name,
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status
),
FinalReport AS (
    SELECT 
        cr.Return_Type,
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.Total_Profit,
        cr.Total_Returned_Quantity,
        cr.Total_Returned_Amount
    FROM 
        TopReturns cr
    JOIN 
        CustomerDetails cd ON cr.Order_Number = cd.c_customer_id
)
SELECT 
    fr.Return_Type,
    COUNT(DISTINCT fr.c_customer_id) AS Customer_Count,
    SUM(fr.Total_Returned_Quantity) AS Total_Refunded_Quantity,
    SUM(fr.Total_Returned_Amount) AS Total_Refunded_Amount,
    AVG(fr.Total_Profit) AS Average_Profit
FROM 
    FinalReport fr
GROUP BY 
    fr.Return_Type
ORDER BY 
    Customer_Count DESC;
