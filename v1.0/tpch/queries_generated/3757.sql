WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_shippriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2023-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(SUM(l.l_discount * l.l_extendedprice), 0) AS total_discounted_sales
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        p.p_size < 30
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
),
RegionNations AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.o_orderstatus,
    ps.total_avail_qty,
    ps.total_supply_value,
    pd.p_name,
    pd.total_discounted_sales,
    rn.nation_count
FROM 
    RankedOrders ro
JOIN 
    SupplierSummary ps ON ro.o_orderkey % 5 = ps.s_suppkey % 5
JOIN 
    PartDetails pd ON pd.p_partkey = (SELECT l.l_partkey 
                                       FROM lineitem l 
                                       WHERE l.l_orderkey = ro.o_orderkey 
                                       ORDER BY l.l_extendedprice DESC 
                                       LIMIT 1)
CROSS JOIN 
    RegionNations rn
WHERE 
    ro.rn <= 10 
    AND (ps.total_supply_value IS NOT NULL OR pd.total_discounted_sales > 0)
ORDER BY 
    ro.o_orderdate, ro.o_totalprice DESC;
