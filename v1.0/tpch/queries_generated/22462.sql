WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rnk
    FROM 
        supplier s
), 
ExtremeOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        DATE_PART('day', o.o_orderdate) as order_day
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < CURRENT_DATE - INTERVAL '1 month')
),
AggregatedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
SuppliersWithInfo AS (
    SELECT 
        r.r_name, 
        n.n_name,
        s.s_name,
        COALESCE(ROUND(SUM(ps.ps_supplycost * ps.ps_availqty), 2), 0) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name, n.n_name, s.s_name
)
SELECT 
    so.o_orderkey,
    so.o_orderstatus,
    so.o_totalprice,
    l.total_revenue,
    s.w_region,
    COALESCE(s.total_cost, 0) AS supplier_total_cost,
    COUNT(DISTINCT CASE WHEN li.l_returnflag = 'R' THEN li.l_partkey END) AS returned_items,
    COUNT(DISTINCT li.l_partkey) FILTER (WHERE li.l_discount > 0.1) AS discounted_items,
    CASE 
        WHEN li.l_shipmode = 'AIR' AND so.o_totalprice > (SELECT AVG(o3.o_totalprice) FROM orders o3) THEN 'High Value Air Shipment'
        ELSE 'Regular Shipment'
    END AS shipment_type
FROM 
    ExtremeOrders so
LEFT JOIN 
    AggregatedLineItems l ON so.o_orderkey = l.l_orderkey
LEFT JOIN 
    SuppliersWithInfo s ON s.s_name IN (SELECT ss.s_name FROM RankedSuppliers ss WHERE ss.rnk <= 3)
LEFT JOIN 
    lineitem li ON l.l_orderkey = li.l_orderkey
GROUP BY 
    so.o_orderkey, so.o_orderstatus, so.o_totalprice, l.total_revenue, s.w_region
HAVING 
    SUM(l.total_revenue) IS NOT NULL AND COUNT(li.l_partkey) > 0
ORDER BY 
    so.o_totalprice DESC NULLS LAST;
