
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt_inc_tax) AS total_return_amt,
        SUM(ws.ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
ReturnReasons AS (
    SELECT 
        r.r_reason_desc,
        COUNT(*) AS reason_count
    FROM 
        store_returns sr
    JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY 
        r.r_reason_desc
),
SalesSummary AS (
    SELECT 
        item.i_item_sk,
        item.i_item_desc,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS avg_price
    FROM 
        item
    JOIN 
        web_sales ws ON item.i_item_sk = ws.ws_item_sk
    GROUP BY 
        item.i_item_sk, item.i_item_desc
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_returns,
    cs.total_return_amt,
    cs.total_sales,
    rr.r_reason_desc AS return_reason,
    ss.total_sold,
    ss.avg_price
FROM 
    CustomerSummary cs
LEFT JOIN 
    ReturnReasons rr ON cs.total_returns > 0
LEFT JOIN 
    SalesSummary ss ON cs.total_sales > 0
WHERE 
    (cs.cd_credit_rating IS NOT NULL OR cs.total_returns > 0)
    AND cs.sales_rank <= 10
ORDER BY 
    cs.total_sales DESC, cs.c_last_name;
