
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS sale_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim) 
        AND ws.ws_net_paid > 0
),
TotalSales AS (
    SELECT 
        item.i_item_id,
        SUM(RankedSales.ws_net_paid) AS total_net_paid,
        SUM(RankedSales.ws_quantity) AS total_quantity,
        COUNT(RankedSales.ws_order_number) AS sales_count
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        RankedSales.sale_rank <= 5
    GROUP BY 
        item.i_item_id
),
CustomerRank AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ts.total_net_paid) AS customer_total_spent,
        COUNT(ts.sales_count) AS purchase_count,
        RANK() OVER (ORDER BY SUM(ts.total_net_paid) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        TotalSales ts ON c.c_customer_sk = ts.total_quantity
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
Summary AS (
    SELECT 
        cr.c_customer_id,
        cr.cd_gender,
        cr.cd_marital_status,
        cr.customer_total_spent,
        COALESCE(ib.ib_income_band_sk, 0) AS income_band_sk
    FROM 
        CustomerRank cr
    LEFT JOIN 
        household_demographics hd ON cr.c_customer_id = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        cr.customer_rank <= 50
)
SELECT 
    s.c_customer_id,
    s.cd_gender,
    s.cd_marital_status,
    s.customer_total_spent,
    COALESCE(i.ib_lower_bound, 0) AS lower_bound,
    COALESCE(i.ib_upper_bound, 0) AS upper_bound
FROM 
    Summary s
FULL OUTER JOIN 
    income_band i ON s.income_band_sk = i.ib_income_band_sk
WHERE 
    (s.customer_total_spent > 1000 OR i.ib_upper_bound IS NULL)
ORDER BY 
    s.customer_total_spent DESC;
