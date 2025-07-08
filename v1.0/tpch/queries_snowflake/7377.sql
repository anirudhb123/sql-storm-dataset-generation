WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as ranking
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > 1000
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) as total_revenue,
        COUNT(*) as total_lines
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderstatus,
    ro.o_totalprice,
    ro.o_orderdate,
    ro.o_orderpriority,
    sd.s_name,
    sd.nation_name,
    sd.region_name,
    lis.total_revenue,
    lis.total_lines
FROM 
    RankedOrders ro
LEFT JOIN 
    LineItemSummary lis ON ro.o_orderkey = lis.l_orderkey
JOIN 
    SupplierDetails sd ON sd.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey) LIMIT 1)
WHERE 
    ro.ranking <= 10
ORDER BY 
    ro.o_orderdate DESC, 
    ro.o_totalprice DESC;