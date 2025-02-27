
WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= CAST('2023-12-31' AS DATE) 
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= CAST('2023-01-01' AS DATE))
    GROUP BY 
        ws.ws_item_sk
),
HighProfitItems AS (
    SELECT 
        s.i_item_id,
        s.i_item_desc,
        s.total_quantity,
        s.total_net_profit
    FROM 
        SalesSummary s
    WHERE 
        s.profit_rank <= 10
),
StoreDetails AS (
    SELECT 
        st.s_store_sk,
        st.s_store_name,
        st.s_city,
        st.s_state,
        CASE 
            WHEN st.s_number_employees IS NULL THEN 'Unknown'
            ELSE CAST(st.s_number_employees AS VARCHAR)
        END AS employee_count
    FROM 
        store st
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    hi.i_item_id,
    hi.i_item_desc,
    hi.total_quantity,
    hi.total_net_profit,
    COALESCE(sr.total_returns, 0) AS total_returns,
    COALESCE(sr.total_return_amount, 0) AS total_return_amount,
    sd.s_store_name,
    sd.s_city,
    sd.s_state,
    sd.employee_count
FROM 
    HighProfitItems hi
LEFT JOIN 
    CustomerReturns sr ON hi.i_item_id = sr.cr_item_sk
CROSS JOIN 
    StoreDetails sd
WHERE 
    (sd.s_state = 'CA' OR sd.s_state = 'TX')
ORDER BY 
    hi.total_net_profit DESC, hi.total_quantity ASC;
