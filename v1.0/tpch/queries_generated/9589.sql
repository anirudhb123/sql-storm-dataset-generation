WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-10-01'
),
TotalQuantityPerSupplier AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        ps.ps_suppkey
),
HighVolumeSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sq.total_quantity
    FROM 
        supplier s
    JOIN 
        TotalQuantityPerSupplier sq ON s.s_suppkey = sq.ps_suppkey
    WHERE 
        sq.total_quantity > 1000
),
FinalMetrics AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        hs.s_name AS top_supplier,
        hs.total_quantity
    FROM 
        RankedOrders ro
    JOIN 
        HighVolumeSuppliers hs ON ro.o_orderkey IN (
            SELECT o.o_orderkey 
            FROM orders o
            JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
            WHERE l.l_suppkey = hs.s_suppkey
        )
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.o_totalprice,
    f.c_name,
    f.top_supplier,
    f.total_quantity
FROM 
    FinalMetrics f
WHERE 
    f.price_rank = 1
ORDER BY 
    f.o_totalprice DESC
LIMIT 10;
