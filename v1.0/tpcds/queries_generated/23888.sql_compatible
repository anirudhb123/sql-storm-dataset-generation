
WITH RankedReturns AS (
    SELECT 
        wr_item_sk,
        wr_order_number,
        SUM(wr_return_quantity) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY wr_item_sk ORDER BY SUM(wr_return_quantity) DESC) AS rnk
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk, wr_order_number
    HAVING 
        SUM(wr_return_quantity) > 0
),

CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS rank_per_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL AND 
        (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
),

TopCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS top_rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),

FinalReport AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COALESCE(SUM(ws.ws_coupon_amt), 0) AS total_coupons_used,
        COUNT(DISTINCT wr.w_returned_date_sk) AS total_returns,
        RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN 
        CustomerDetails cd ON c.c_customer_id = cd.c_customer_id
    LEFT JOIN 
        RankedReturns rr ON wr.wr_order_number = rr.wr_order_number
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
)

SELECT 
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.total_spent,
    f.total_coupons_used,
    f.total_returns,
    f.sales_rank,
    CASE 
        WHEN f.total_returns > 2 THEN 'High Return Rate'
        WHEN f.total_returns BETWEEN 1 AND 2 THEN 'Normal Return Rate'
        ELSE 'No Returns'
    END AS return_status,
    (SELECT AVG(cd.cd_purchase_estimate) 
        FROM CustomerDetails cd 
        WHERE cd.rank_per_state <= 10) AS avg_purchase_of_top_customers
FROM 
    FinalReport f
WHERE 
    f.total_spent IS NOT NULL
ORDER BY 
    f.total_spent DESC, f.sales_rank;
