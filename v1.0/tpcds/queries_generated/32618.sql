
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_sales
    FROM 
        SalesCTE sales
    JOIN 
        item ON sales.ss_item_sk = item.i_item_sk
    WHERE 
        sales.sales_rank <= 10
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr.ticket_number) AS return_count,
        SUM(sr.return_amt) AS total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
ReturnMetrics AS (
    SELECT 
        customer_id,
        return_count,
        total_return_amt,
        (CASE 
            WHEN total_return_amt IS NULL THEN 0 
            ELSE total_return_amt 
        END) AS adjusted_return_amt
    FROM 
        CustomerStats
),
FinalResults AS (
    SELECT 
        ti.i_item_id,
        ti.i_item_desc,
        cs.customer_id,
        cs.return_count,
        cs.adjusted_return_amt,
        (CASE 
            WHEN cs.return_count > 0 THEN 
                (ti.total_sales / NULLIF(cs.return_count, 0)) * 100 
            ELSE 
                ti.total_sales 
        END) AS sales_per_return
    FROM 
        TopItems ti
    JOIN 
        ReturnMetrics cs ON ti.total_sales > 0
)
SELECT 
    f.i_item_id,
    f.i_item_desc,
    f.customer_id,
    f.return_count,
    f.adjusted_return_amt,
    f.sales_per_return
FROM 
    FinalResults f
ORDER BY 
    f.sales_per_return DESC
LIMIT 100;
