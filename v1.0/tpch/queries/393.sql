
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierRegionStats AS (
    SELECT 
        n.n_name AS nation,
        r.r_name AS region,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(s.s_acctbal) AS avg_supplier_acctbal
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
),
OrderLineStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
        COUNT(*) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1998-10-01' - INTERVAL '1 year'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    oo.o_orderkey,
    oo.o_orderdate,
    oo.o_totalprice,
    sr.total_available_qty,
    sr.avg_supplier_acctbal,
    ol.net_sales,
    ol.line_count,
    CASE 
        WHEN ol.net_sales IS NULL THEN 'No Sales'
        WHEN ol.net_sales >= 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS sales_value_category
FROM 
    RankedOrders oo
LEFT JOIN 
    SupplierRegionStats sr ON oo.c_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_name = sr.nation
        FETCH FIRST 1 ROW ONLY
    )
LEFT JOIN 
    OrderLineStats ol ON oo.o_orderkey = ol.l_orderkey
WHERE 
    oo.order_rank = 1
ORDER BY 
    oo.o_orderdate DESC, oo.o_totalprice DESC;
