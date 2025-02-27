WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.total_parts,
        sd.total_supply_value
    FROM 
        SupplierDetails sd
    WHERE 
        sd.total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierDetails)
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.nation_name,
    cr.region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_sales,
    COALESCE(MAX(ho.order_rank), 0) AS highest_order_rank,
    AVG(CASE 
        WHEN hi.total_parts > 10 THEN hi.total_supply_value 
        ELSE NULL 
    END) AS avg_high_value_supply
FROM 
    CustomerRegion cr
LEFT JOIN 
    RankedOrders ho ON cr.c_custkey = ho.o_orderkey
LEFT JOIN 
    HighValueSuppliers hi ON hi.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ho.o_orderkey))
LEFT JOIN 
    lineitem l ON l.l_orderkey = ho.o_orderkey
GROUP BY 
    cr.nation_name,
    cr.region_name
ORDER BY 
    total_sales DESC, 
    nation_name ASC
