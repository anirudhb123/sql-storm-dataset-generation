WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
RegionOrderCounts AS (
    SELECT 
        n.n_regionkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_regionkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < GETDATE() - INTERVAL '30 DAY'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_regionkey,
    roc.order_count,
    COALESCE(SUM(l.total_revenue), 0) AS total_income,
    COUNT(DISTINCT so.s_suppkey) AS unique_suppliers,
    AVG(ss.avg_supply_cost) AS avg_cost_per_supplier
FROM 
    RegionOrderCounts roc
LEFT JOIN 
    region r ON r.r_regionkey = roc.n_regionkey
LEFT JOIN 
    FilteredLineItems l ON l.l_orderkey IN (SELECT o.o_orderkey FROM RankedOrders o WHERE o.rnk <= 5)
LEFT JOIN 
    SupplierStats ss ON ss.total_available > 0
LEFT JOIN 
    supplier so ON ss.s_suppkey = so.s_suppkey AND so.s_acctbal IS NOT NULL
GROUP BY 
    r.r_regionkey, roc.order_count
ORDER BY 
    total_income DESC, order_count DESC;
