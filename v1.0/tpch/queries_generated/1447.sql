WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-12-31'
),
SupplierStats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
TotalSales AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
RegionSuppliers AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.o_orderstatus,
    ts.total_revenue,
    ss.total_avail_qty,
    ss.avg_supply_cost,
    rs.r_name,
    rs.supplier_count
FROM 
    RankedOrders ro
LEFT JOIN 
    TotalSales ts ON ro.o_orderkey = ts.l_orderkey
JOIN 
    SupplierStats ss ON ss.ps_suppkey = (SELECT ps.ps_suppkey 
                                          FROM partsupp ps 
                                          WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                                  FROM part p 
                                                                  WHERE p.p_retailprice > 100.00))
LEFT JOIN 
    RegionSuppliers rs ON rs.supplier_count >= 5
WHERE 
    ro.rn <= 10
ORDER BY 
    ro.o_orderdate DESC, 
    ro.o_totalprice DESC;
