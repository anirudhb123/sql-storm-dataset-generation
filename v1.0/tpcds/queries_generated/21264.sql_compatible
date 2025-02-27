
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY ws.ws_item_sk, ws.ws_order_number
),
TopItemSales AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_net_profit
    FROM RankedSales
    WHERE rank <= 5
),
ItemDetails AS (
    SELECT 
        i.i_item_id, 
        i.i_product_name, 
        i.i_current_price, 
        ts.total_quantity, 
        ts.total_net_profit,
        COALESCE(NULLIF(i.i_size, ''), 'Unknown') AS item_size
    FROM item i
    JOIN TopItemSales ts ON i.i_item_sk = ts.ws_item_sk
),
SalesSummary AS (
    SELECT 
        id.i_item_id,
        id.i_product_name,
        id.item_size,
        id.total_quantity,
        id.total_net_profit,
        (id.total_net_profit / NULLIF(id.total_quantity, 0)) AS profit_per_item
    FROM ItemDetails id
),
CustomerIncomeBand AS (
    SELECT DISTINCT
        c.c_customer_id,
        ib.ib_income_band_sk,
        CASE 
            WHEN c.c_customer_id IS NULL THEN 'Unknown'
            ELSE c.c_customer_id
        END AS customer_identifier
    FROM customer c
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
FinalReport AS (
    SELECT 
        s.i_item_id,
        s.i_product_name,
        s.item_size,
        s.total_quantity,
        s.total_net_profit,
        s.profit_per_item,
        COUNT(DISTINCT hib.ib_income_band_sk) AS unique_income_bands
    FROM SalesSummary s
    LEFT JOIN CustomerIncomeBand hib ON hib.c_customer_id IN (SELECT DISTINCT c_customer_id FROM customer)
    GROUP BY s.i_item_id, s.i_product_name, s.item_size, s.total_quantity, s.total_net_profit, s.profit_per_item
)
SELECT 
    f.i_item_id,
    f.i_product_name,
    f.item_size,
    f.total_quantity,
    f.total_net_profit,
    f.profit_per_item,
    CASE 
        WHEN unique_income_bands > 2 THEN 'Multi-Range'
        ELSE 'Single-Range'
    END AS income_band_status
FROM FinalReport f
WHERE f.total_net_profit IS NOT NULL
ORDER BY f.total_net_profit DESC
LIMIT 10;
