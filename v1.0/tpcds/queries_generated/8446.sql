
WITH RankedReturns AS (
    SELECT 
        wr.returned_date_sk,
        wr.returning_customer_sk,
        wr.return_quantity,
        wr.return_amt,
        wr.return_tax,
        ROW_NUMBER() OVER (PARTITION BY wr.returning_customer_sk ORDER BY wr.returned_date_sk DESC) as return_rank
    FROM 
        web_returns wr
),
TopCustomers AS (
    SELECT 
        returning_customer_sk,
        SUM(return_quantity) AS total_returned_quantity,
        SUM(return_amt) AS total_returned_amount,
        SUM(return_tax) AS total_returned_tax
    FROM 
        RankedReturns
    WHERE 
        return_rank <= 5
    GROUP BY 
        returning_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        cd.education_status,
        cd.credit_rating,
        cd.marital_status,
        dc.month_seq, 
        SUM(ws.net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.bill_customer_sk
    JOIN 
        date_dim dc ON ws.sold_date_sk = dc.d_date_sk
    JOIN 
        TopCustomers tc ON c.c_customer_sk = tc.returning_customer_sk
    GROUP BY 
        c.customer_id, c.first_name, c.last_name, cd.education_status, cd.credit_rating, cd.marital_status, dc.month_seq
)
SELECT 
    customer_id,
    first_name,
    last_name,
    education_status,
    credit_rating,
    marital_status,
    month_seq,
    total_net_profit
FROM 
    CustomerDetails
ORDER BY 
    total_net_profit DESC 
LIMIT 10;
