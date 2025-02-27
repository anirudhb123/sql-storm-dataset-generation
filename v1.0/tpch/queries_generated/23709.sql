WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        r.r_name,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, r.r_name
),
PartSuppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        AVG(ps.ps_supplycost) IS NOT NULL AND num_suppliers > 0
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sr.r_name, 'Unknown') AS region_name,
    po.total_revenue,
    ps.num_suppliers,
    ps.avg_supply_cost,
    ps.total_avail_qty,
    ROW_NUMBER() OVER (PARTITION BY sr.r_name ORDER BY total_revenue DESC) AS revenue_rank
FROM 
    PartSuppliers ps
LEFT JOIN 
    SupplierRegion sr ON sr.total_avail_qty > ps.total_avail_qty * 0.1
LEFT JOIN 
    RankedOrders po ON po.o_orderkey = (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderdate = (
                SELECT 
                    MAX(o2.o_orderdate) 
                FROM 
                    orders o2 
                WHERE 
                    o2.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = ps.p_partkey)
            )
        LIMIT 1
    )
WHERE 
    ps.avg_supply_cost > (
        SELECT 
            AVG(ps2.ps_supplycost) 
        FROM 
            partsupp ps2 
        WHERE 
            ps2.ps_availqty IS NOT NULL
    )
ORDER BY 
    region_name, revenue_rank;
