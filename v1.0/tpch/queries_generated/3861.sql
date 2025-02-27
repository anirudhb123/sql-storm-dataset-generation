WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_name AS supplier_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS total_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_extended_price,
        AVG(l.l_tax) AS average_tax
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    l.total_items,
    l.total_extended_price,
    sp.supplier_name,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN ro.o_totalprice > 1000 THEN 'High'
        WHEN ro.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS price_category
FROM 
    RankedOrders ro
LEFT JOIN 
    LineItemSummary l ON ro.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierParts sp ON l.total_items > 0 AND sp.ps_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps
        WHERE ps.ps_availqty > 0
    )
WHERE 
    ro.order_rank <= 5
ORDER BY 
    ro.o_orderdate DESC, ro.o_orderkey;
