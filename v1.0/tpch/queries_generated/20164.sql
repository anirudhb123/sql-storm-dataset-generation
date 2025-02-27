WITH RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_linenumber,
        l.l_quantity,
        l.l_extendedprice * (1 - l.l_discount) AS discounted_price,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS item_rank
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > '2023-01-01' AND 
        l.l_shipdate <= CURRENT_DATE
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(r.discounted_price) AS total_discounted_price,
        COUNT(r.item_rank) AS total_items,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Completed'
            WHEN o.o_orderstatus = 'P' AND COUNT(r.item_rank) = 0 THEN 'Pending - No items'
            ELSE 'In Progress'
        END AS order_status_description
    FROM 
        orders o
    LEFT JOIN 
        RankedLineItems r ON o.o_orderkey = r.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
FinalResults AS (
    SELECT 
        od.o_orderkey,
        od.order_status_description,
        od.total_discounted_price,
        od.total_items,
        r.n_name AS nation_name,
        CASE 
            WHEN od.total_discounted_price IS NULL THEN 'No Total Price Available'
            WHEN od.total_discounted_price > 1000 THEN 'High Value Order'
            ELSE 'Regular Order'
        END AS price_category
    FROM 
        OrderDetails od
    LEFT JOIN 
        supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey 
                                       FROM partsupp ps 
                                       WHERE ps.ps_partkey IN (SELECT l.l_partkey 
                                                               FROM lineitem l 
                                                               WHERE l.l_orderkey = od.o_orderkey) 
                                       ORDER BY ps.ps_supplycost ASC 
                                       FETCH FIRST 1 ROW ONLY)
    LEFT JOIN 
        nation r ON s.s_nationkey = r.n_nationkey
)
SELECT 
    *,
    CASE 
        WHEN total_items = 0 THEN NULL 
        ELSE total_discounted_price / total_items 
    END AS average_price_per_item
FROM 
    FinalResults
WHERE 
    (price_category = 'High Value Order' OR nation_name IS NOT NULL)
ORDER BY 
    total_discounted_price DESC, 
    o_orderkey 
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
