
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_marital_status, 'UNKNOWN') AS marital_status,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd.cd_demo_sk) AS demo_count,
        DENSE_RANK() OVER (ORDER BY AVG(cd.cd_purchase_estimate) DESC) AS demo_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_marital_status
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        COUNT(*) AS total_sales_transactions,
        SUM(ss.ss_net_profit) AS total_profit,
        MAX(ss.ss_sales_price) AS max_sale_price
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN (
            SELECT MIN(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2022
        ) AND (
            SELECT MAX(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2022
        )
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    st.s_store_id,
    COALESCE(sales.total_quantity, 0) AS total_quantity,
    s_summary.total_sales_transactions,
    s_summary.total_profit,
    st.s_tax_precentage,
    cs.marital_status,
    cs.avg_purchase_estimate,
    cs.demo_count
FROM 
    store st
LEFT JOIN 
    RankedSales sales ON sales.ws_item_sk = (
        SELECT ws.ws_item_sk 
        FROM web_sales ws 
        WHERE ws.ws_quantity = (
            SELECT MAX(ws2.ws_quantity) 
            FROM web_sales ws2 
            WHERE ws2.ws_item_sk = sales.ws_item_sk
        )
        LIMIT 1
    )
LEFT JOIN 
    StoreSalesSummary s_summary ON st.s_store_sk = s_summary.ss_store_sk
LEFT JOIN 
    CustomerStats cs ON cs.c_customer_sk = (
        SELECT c.c_customer_sk 
        FROM customer c 
        WHERE c.c_first_name = 'John' AND c.c_last_name = 'Doe'
        LIMIT 1
    )
WHERE 
    st.s_state = 'CA'
    AND (s_summary.total_profit IS NULL OR s_summary.total_profit > 0)
ORDER BY 
    total_quantity DESC, 
    s_summary.total_profit DESC
FETCH FIRST 100 ROWS ONLY;
