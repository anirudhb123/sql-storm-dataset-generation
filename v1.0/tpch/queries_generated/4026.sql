WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
RevenueByRegion AS (
    SELECT 
        n.n_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate >= '2023-01-01'
    GROUP BY 
        n.n_nationkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(PartSold.total_quantity, 0) AS total_quantity_sold,
    COALESCE(SupplierStats.part_count, 0) AS supplier_part_count,
    R.total_revenue AS revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY COALESCE(R.total_revenue, 0) DESC) AS revenue_rank
FROM 
    part p
LEFT JOIN (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        l.l_partkey
) AS PartSold ON p.p_partkey = PartSold.l_partkey
LEFT JOIN SupplierStats ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = SupplierStats.s_suppkey)
LEFT JOIN RevenueByRegion R ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = R.total_revenue)
ORDER BY 
    p.p_partkey;
