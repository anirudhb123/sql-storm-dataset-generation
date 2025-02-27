WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    r.r_name AS region_name,
    nd.n_name AS nation_name,
    sd.s_name AS supplier_name,
    sd.total_available,
    sd.total_cost,
    ro.total_order_value,
    ro.line_item_count
FROM 
    region r
JOIN 
    nation nd ON r.r_regionkey = nd.n_regionkey
JOIN 
    supplier s ON nd.n_nationkey = s.s_nationkey
JOIN 
    SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
LEFT JOIN 
    RecentOrders ro ON s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey = ro.o_orderkey
        )
    )
WHERE 
    sd.total_cost > 50000
ORDER BY 
    region_name, nation_name, total_order_value DESC;
