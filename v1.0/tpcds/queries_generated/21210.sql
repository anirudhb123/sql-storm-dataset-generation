
WITH RankedReturns AS (
    SELECT 
        cr.returning_customer_sk,
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        RANK() OVER (PARTITION BY cr.returning_customer_sk ORDER BY SUM(cr.cr_return_quantity) DESC) AS rank
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_return_date_sk IS NOT NULL
    GROUP BY 
        cr.returning_customer_sk, cr.cr_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales,
        AVG(DISTINCT DATEDIFF(DAY, c.c_first_sales_date_sk, GETDATE())) AS avg_days_since_first_purchase
    FROM 
        customer c 
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, hd.hd_buy_potential
),
FinalReport AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.hd_buy_potential,
        cs.total_web_returns,
        cs.total_sales,
        rr.cr_item_sk,
        rr.total_returned
    FROM 
        CustomerStats cs
    LEFT JOIN RankedReturns rr ONcs.c_customer_id = rr.returning_customer_sk
    WHERE 
        cs.hd_buy_potential IS NOT NULL 
        AND (cs.total_sales > AVG(cs.total_sales) OVER() OR cs.total_web_returns > 0)
)
SELECT 
    f.c_customer_id,
    f.cd_gender,
    f.hd_buy_potential,
    f.total_web_returns,
    f.total_sales,
    COALESCE(f.total_returned, 0) AS returned_items,
    CASE 
        WHEN f.total_sales > 0 THEN ROUND((f.total_sales - f.total_web_returns) / f.total_sales * 100, 2)
        ELSE NULL 
    END AS return_percentage
FROM 
    FinalReport f
ORDER BY 
    return_percentage DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
