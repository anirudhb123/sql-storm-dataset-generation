
WITH RECURSIVE customer_incomes AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(hd.ib_income_band_sk, 0) AS income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(hd.ib_income_band_sk, 0)) AS income_rank
    FROM 
        customer c
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_info AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        w.w_warehouse_name
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        ws.ws_sold_date_sk, w.w_warehouse_name
),
return_info AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS return_amount,
        SUM(sr_return_tax) AS return_tax,
        COALESCE(NULLIF(SUM(sr_return_qty), 0), 1) AS effective_return_qty
    FROM 
        store_returns 
    GROUP BY 
        sr_returned_date_sk
),
combined AS (
    SELECT 
        di.d_date_id,
        ci.c_customer_sk,
        ci.income_band_sk,
        si.total_sales,
        si.total_quantity,
        ri.total_returns,
        ri.return_amount,
        ri.return_tax,
        (si.total_sales - COALESCE(ri.return_amount, 0)) AS net_sales,
        (CASE 
            WHEN si.total_quantity IS NULL THEN 0 
            ELSE (si.total_sales / NULLIF(si.total_quantity, 0))
        END) AS avg_sales_per_item
    FROM 
        date_dim di
    LEFT JOIN 
        customer_incomes ci ON ci.income_rank = 1
    LEFT JOIN 
        sales_info si ON di.d_date_sk = si.ws_sold_date_sk
    LEFT JOIN 
        return_info ri ON ri.sr_returned_date_sk = di.d_date_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cb.income_band_sk,
    COALESCE(cb.total_sales, 0) AS total_sales,
    COALESCE(cb.total_quantity, 0) AS total_quantity,
    cb.total_returns,
    cb.return_amount,
    cb.return_tax,
    cb.net_sales,
    cb.avg_sales_per_item
FROM 
    combined cb
JOIN 
    customer c ON cb.c_customer_sk = c.c_customer_sk
WHERE 
    ((cb.net_sales > 1000 AND cb.total_quantity > 5) OR cb.total_returns IS NULL)
ORDER BY 
    cb.net_sales DESC, c.c_last_name ASC;
