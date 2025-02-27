WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_mktsegment = 'BUILDING')
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 2
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
        AND l.l_shipdate <= DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    COALESCE(lis.total_revenue, 0) AS total_revenue,
    COALESCE(lis.item_count, 0) AS item_count,
    sa.total_avail_qty
FROM 
    RankedOrders ro
LEFT JOIN 
    LineItemSummary lis ON ro.o_orderkey = lis.l_orderkey
JOIN 
    SupplierAvailability sa ON sa.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey)
WHERE 
    ro.order_rank <= 5
ORDER BY 
    ro.o_orderdate DESC, ro.o_orderkey;