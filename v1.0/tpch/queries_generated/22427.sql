WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' AND 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = o.o_orderstatus)
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        ROUND(SUM(ps.ps_supplycost) OVER (PARTITION BY s.s_suppkey), 2) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) OVER (PARTITION BY s.s_suppkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND 
        s.s_acctbal > 500.00
),
OrderLineDetails AS (
    SELECT 
        lo.l_orderkey,
        lo.l_partkey,
        lo.l_quantity,
        lo.l_discount,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) OVER (PARTITION BY lo.l_orderkey) as net_revenue,
        COUNT(*) OVER (PARTITION BY lo.l_orderkey) as line_item_count,
        CASE 
            WHEN lo.l_discount = 0 THEN 'No Discount' 
            ELSE 'Discounted' 
        END as discount_status
    FROM 
        lineitem lo
)
SELECT 
    r.o_orderkey,
    r.o_orderstatus,
    r.o_totalprice,
    COALESCE(sd.s_name, 'Unknown Supplier') AS supplier_name,
    ol.line_item_count,
    ol.discount_status,
    ol.net_revenue,
    CASE 
        WHEN ol.line_item_count > 1 AND r.o_orderstatus = 'F' THEN 'High Volume'
        WHEN ol.net_revenue > (SELECT AVG(net_revenue) FROM OrderLineDetails) THEN 'Above Average Revenue'
        ELSE 'Regular Order'
    END AS order_category
FROM 
    RankedOrders r
LEFT JOIN 
    OrderLineDetails ol ON r.o_orderkey = ol.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON ol.l_partkey = (SELECT MIN(ps.ps_partkey) FROM partsupp ps WHERE ps.ps_availqty > 0)
WHERE 
    ol.l_quantity IS NOT NULL AND 
    ol.discount_status = 'Discounted'
ORDER BY 
    r.o_orderdate DESC, r.o_orderkey ASC;
