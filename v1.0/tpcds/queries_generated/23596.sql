
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_day_name = 'Saturday')
),
StoreAggregates AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM 
        store_sales ss
    INNER JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_month = 2 AND c.c_birth_day BETWEEN 1 AND 29
    GROUP BY 
        ss.ss_store_sk
),
HighValueReturns AS (
    SELECT 
        sr_invoice_quantity,
        sr_return_amt,
        coalesce(sr_return_amt / NULLIF(sr_invoice_quantity, 0), 0) AS return_amount_per_item
    FROM 
        store_returns sr
    WHERE 
        sr_return_amt > 100
),
FinalReport AS (
    SELECT 
        a.ws_item_sk,
        SUM(s.total_net_paid) AS total_sales,
        AVG(h.return_amount_per_item) AS avg_return_value,
        COUNT(DISTINCT s.ss_store_sk) AS store_count
    FROM 
        RankedSales a
    LEFT JOIN 
        StoreAggregates s ON a.ws_item_sk = s.ss_store_sk
    LEFT JOIN 
        HighValueReturns h ON a.ws_order_number = h.sr_ticket_number
    WHERE 
        a.rank_sales <= 5 AND (s.total_quantity IS NULL OR s.total_quantity > 10)
    GROUP BY 
        a.ws_item_sk
)
SELECT 
    f.ws_item_sk,
    f.total_sales,
    COALESCE(f.avg_return_value, 0) AS avg_return_value,
    f.store_count
FROM 
    FinalReport f
WHERE 
    EXISTS (
        SELECT 1 
        FROM warehouse w 
        WHERE w.w_warehouse_sk = (
            SELECT s.s_store_sk 
            FROM store s 
            WHERE s.s_closed_date_sk IS NULL 
            LIMIT 1
        )
    )
ORDER BY 
    f.total_sales DESC, f.avg_return_value ASC;
