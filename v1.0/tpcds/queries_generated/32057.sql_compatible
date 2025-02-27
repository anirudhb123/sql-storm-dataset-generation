
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
    HAVING 
        COUNT(*) > 0
),
ReturnableItems AS (
    SELECT 
        sr_item_sk,
        SUM(CASE 
            WHEN sr_return_quantity > 0 THEN sr_return_quantity 
            ELSE 0 END) AS total_returnable_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_credit_rating,
        cd.cd_marital_status,
        cr.total_returns,
        cr.total_return_amt,
        DENSE_RANK() OVER (ORDER BY cr.total_return_amt DESC) AS return_rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerReturns AS cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_credit_rating IN ('Good', 'Better')
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_color,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_sales_quantity,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales_value,
        COALESCE(ri.total_returnable_quantity, 0) AS total_returnable_quantity
    FROM 
        item AS i
    LEFT JOIN 
        web_sales AS ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        ReturnableItems AS ri ON i.i_item_sk = ri.sr_item_sk
    GROUP BY 
        i.i_item_id, i.i_product_name, i.i_color
),
FinalReport AS (
    SELECT 
        t.c_customer_id,
        t.cd_gender,
        t.cd_credit_rating,
        t.cd_marital_status,
        id.total_sales_quantity,
        id.total_sales_value,
        id.total_returnable_quantity,
        id.total_sales_value - id.total_returnable_quantity AS net_sales_value
    FROM 
        TopCustomers AS t
    JOIN 
        ItemDetails AS id ON t.return_rank <= 10
)
SELECT 
    c.c_customer_id,
    COALESCE(SUM(fr.total_sales_value), 0) AS total_net_sales
FROM 
    customer AS c
LEFT JOIN 
    FinalReport AS fr ON c.c_customer_id = fr.c_customer_id
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_net_sales DESC
LIMIT 10;
