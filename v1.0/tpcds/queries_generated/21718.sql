
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS spend_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_purchase_estimate > 1000 
        AND (c.c_birth_year IS NOT NULL OR c.c_birth_month IS NOT NULL)
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender
),
RetunedSales AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
WebReturnsSummary AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_amt) AS total_web_return_amt,
        AVG(wr_return_quantity) AS avg_web_return_quantity,
        COUNT(*) AS total_web_returns,
        MAX(wr_return_tax) AS max_web_return_tax
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_web_sales,
        SUM(ws.ws_sales_price) AS total_sales_value,
        COALESCE(ws_ext_discount_amt, 0) AS ext_discount,
        d.d_date AS sales_date,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, d.d_date, ws_ext_discount_amt
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    rc.total_orders,
    rc.total_spent,
    rc.spend_rank,
    is.i_item_id,
    is.total_web_sales,
    is.total_sales_value,
    ir.total_returns,
    wr.total_web_return_amt,
    wr.avg_web_return_quantity,
    wr.max_web_return_tax
FROM 
    RankedCustomers rc
LEFT JOIN 
    ItemSales is ON rc.total_orders > 5 AND is.sales_rank <= 10
LEFT JOIN 
    RetunedSales ir ON ir.sr_item_sk = is.i_item_sk
LEFT JOIN 
    WebReturnsSummary wr ON wr.wr_item_sk = is.i_item_sk
WHERE 
    (rc.total_spent > 5000 OR rc.total_orders > 10)
    AND (wr.total_web_returns IS NULL OR wr.total_web_returns > 1)
ORDER BY 
    rc.spend_rank, rc.total_spent DESC, is.total_sales_value;
