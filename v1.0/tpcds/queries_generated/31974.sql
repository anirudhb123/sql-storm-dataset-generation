
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk,
        ws_name,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_sk, w.web_name
),
IncomeRanges AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        CASE 
            WHEN ib_lower_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('$', ib_lower_bound, ' - $', ib_upper_bound)
        END AS income_range_desc
    FROM 
        income_band
),
CustomerReturns AS (
    SELECT 
        CASE 
            WHEN cr_return_quantity > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status,
        COUNT(*) AS return_count,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        return_status
),
FinalReport AS (
    SELECT 
        c.c_customer_id,
        d.d_date,
        ca.ca_city,
        SUM(ws.ws_net_profit) AS total_profit,
        COALESCE(ir.income_range_desc, 'Unknown') AS income_rank,
        COUNT(DISTINCT cr.return_count) AS total_returns,
        AVG(ws.ws_net_paid_inc_tax) AS avg_amount_spent,
        MAX(ws.ws_net_profit) AS max_single_sale
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        IncomeRanges ir ON cd.cd_purchase_estimate BETWEEN ir.ib_lower_bound AND ir.ib_upper_bound
    LEFT JOIN 
        CustomerReturns cr ON cr.return_status = 
            (CASE 
                WHEN SUM(ws.ws_net_profit) < 0 THEN 'Returned'
                ELSE 'Not Returned'
             END)
    GROUP BY 
        c.c_customer_id, d.d_date, ca.ca_city, ir.income_range_desc
)
SELECT 
    customer_id,
    d_date,
    ca_city,
    total_profit,
    income_rank,
    total_returns,
    avg_amount_spent,
    max_single_sale
FROM 
    FinalReport
WHERE 
    total_profit > (
        SELECT 
            AVG(total_profit) 
        FROM 
            FinalReport
    )
ORDER BY 
    total_profit DESC, d_date DESC;
