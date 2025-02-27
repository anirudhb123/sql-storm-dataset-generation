WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o 
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE) 
        AND o.o_orderstatus IN ('O', 'F')
), 
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_name) AS unique_suppliers
    FROM 
        partsupp ps 
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
ExtendedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        CASE 
            WHEN l.l_discount > 0.1 THEN l.l_extendedprice * l.l_discount 
            ELSE NULL 
        END AS discount_amount,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_num
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATEADD(month, -3, CURRENT_DATE) AND CURRENT_DATE
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(pt.total_supply_cost, 0) AS supply_cost,
    COALESCE(lp.discount_amount, 0) AS discount,
    ROW_NUMBER() OVER (ORDER BY r.o_totalprice DESC) AS order_rank,
    CASE 
        WHEN r.o_orderstatus = 'O' AND (lp.discount_amount IS NULL OR lp.discount_amount = 0) THEN 'Order Pending - No Discount' 
        ELSE 'Other Status' 
    END AS status_comment
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierPartDetails pt ON r.o_orderkey = pt.ps_partkey
LEFT JOIN 
    ExtendedLineItems lp ON r.o_orderkey = lp.l_orderkey
WHERE 
    rnk <= 5 
    AND (pt.unique_suppliers > 1 OR pt.total_supply_cost IS NULL)
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice DESC;
