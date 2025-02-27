
WITH RankedReturns AS (
    SELECT
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.return_tax,
        sr.return_amt_inc_tax,
        sr.store_sk,
        RANK() OVER (PARTITION BY sr.item_sk ORDER BY sr.returned_date_sk DESC) AS return_rank
    FROM 
        store_returns sr
),
InventoryStatus AS (
    SELECT
        inv.item_sk,
        inv.warehouse_sk,
        SUM(inv.quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.item_sk,
        inv.warehouse_sk
),
CustomerDetails AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        cd.purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
),
ReturnTrends AS (
    SELECT 
        r.returned_date_sk,
        COUNT(*) AS total_returns,
        SUM(r.return_amt) AS total_returned_amount,
        SUM(r.return_quantity) AS total_returned_quantity,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS trend_rank
    FROM 
        RankedReturns r
    GROUP BY 
        r.returned_date_sk
)
SELECT
    cd.first_name,
    cd.last_name,
    cd.gender,
    cd.marital_status,
    cd.education_status,
    cd.purchase_estimate,
    it.item_desc,
    inv.total_quantity_on_hand,
    rt.total_returns,
    rt.total_returned_amount,
    rt.total_returned_quantity
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedReturns rr ON cd.customer_sk = rr.customer_sk
LEFT JOIN 
    InventoryStatus inv ON rr.item_sk = inv.item_sk
LEFT JOIN 
    item it ON rr.item_sk = it.item_sk
LEFT JOIN 
    ReturnTrends rt ON rr.returned_date_sk = rt.returned_date_sk
WHERE 
    rr.return_rank <= 5 AND rt.trend_rank <= 10
ORDER BY 
    cd.last_name, cd.first_name;
