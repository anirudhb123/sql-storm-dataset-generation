WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_brand,
        p.p_type,
        p.p_size
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_regionkey,
        r.r_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
SalesData AS (
    SELECT 
        coalesce(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
        r.r_name
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        CustomerRegion r ON o.o_custkey = r.c_custkey
    WHERE 
        l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        r.r_name
)
SELECT 
    cr.r_name,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    AVG(sp.ps_supplycost) AS avg_supply_cost
FROM 
    CustomerRegion cr
LEFT JOIN 
    SalesData sd ON cr.r_name = sd.r_name
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey IN (
        SELECT 
            ps_partkey 
        FROM 
            partsupp 
        WHERE 
            ps_availqty > 0
    )
LEFT JOIN 
    RankedOrders ro ON cr.c_custkey = ro.o_custkey AND ro.rn = 1
GROUP BY 
    cr.r_name
ORDER BY 
    total_sales DESC NULLS LAST;
