WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            WHEN o.o_orderstatus = 'P' THEN 'Pending'
            ELSE 'Unknown'
        END AS order_type
    FROM 
        orders o
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        s.s_name, 
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
),
HighValueLines AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        COUNT(*) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS line_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000 OR COUNT(*) > 3
)
SELECT 
    ro.o_orderkey, 
    ro.o_totalprice, 
    sr.region_name,
    hl.total_value,
    ro.order_type,
    CASE 
        WHEN ro.price_rank = 1 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_rank,
    COALESCE(NULLIF(hl.line_count, 0), 'No Lines') AS line_information
FROM 
    RankedOrders ro
LEFT JOIN 
    HighValueLines hl ON ro.o_orderkey = hl.l_orderkey
LEFT JOIN 
    SupplierRegion sr ON sr.total_cost >= (SELECT AVG(total_cost) FROM SupplierRegion)
WHERE 
    ro.o_orderdate < DATEADD(day, -30, GETDATE())
ORDER BY 
    ro.o_totalprice DESC, 
    sr.region_name ASC;
