
WITH TopCustomers AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
HighIncomeDemographic AS (
    SELECT 
        hd.hd_demo_sk, 
        ib.ib_income_band_sk
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ib.ib_upper_bound > 100000
),
SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        TopCustomers tc ON ws.ws_bill_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = tc.c_customer_id)
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    sd.total_quantity, 
    sd.total_sales, 
    COUNT(DISTINCT h.hd_demo_sk) AS demographic_count
FROM 
    item i
JOIN 
    SalesData sd ON i.i_item_sk = sd.ws_item_sk
JOIN 
    web_returns wr ON wr.wr_item_sk = sd.ws_item_sk
LEFT JOIN 
    HighIncomeDemographic h ON wr.wr_returning_cdemo_sk = h.hd_demo_sk
WHERE 
    sd.total_sales > 5000
GROUP BY 
    i.i_item_id, i.i_item_desc, sd.total_quantity, sd.total_sales
ORDER BY 
    total_sales DESC;
