
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_credit_rating IS NOT NULL
    GROUP BY 
        c.c_customer_id,
        cd.cd_gender
),
MaxIncome AS (
    SELECT 
        ib.ib_income_band_sk,
        MAX(hd.hd_buy_potential) as max_buy_potential
    FROM 
        household_demographics AS hd
    JOIN 
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.order_count,
    cs.total_spent,
    COALESCE(ri.max_income_band, 'UNKNOWN') AS max_income_band,
    COALESCE(rs.ws_sales_price, 0) AS highest_price_sales
FROM 
    CustomerStats AS cs
LEFT JOIN 
    MaxIncome AS ri ON cs.total_spent > 1000
LEFT JOIN 
    RankedSales AS rs ON cs.order_count = 1
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
ORDER BY 
    total_spent DESC, order_count ASC;
