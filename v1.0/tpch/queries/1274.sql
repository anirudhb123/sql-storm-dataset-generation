WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighRevenueOrders AS (
    SELECT 
        r.r_name,
        SUM(ho.revenue) AS total_revenue
    FROM 
        RankedOrders ho
    JOIN 
        customer c ON c.c_custkey = (
            SELECT o.o_custkey 
            FROM orders o 
            WHERE o.o_orderkey = ho.o_orderkey
        )
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    COALESCE(h.total_revenue, 0) AS total_revenue,
    ss.avg_supplycost,
    ss.part_count,
    CASE 
        WHEN h.total_revenue IS NULL THEN 'No Revenue'
        ELSE 'Revenue Available'
    END AS revenue_status
FROM 
    region r
LEFT JOIN 
    HighRevenueOrders h ON r.r_name = h.r_name
LEFT JOIN 
    SupplierStats ss ON ss.avg_supplycost > (SELECT AVG(avg_supplycost) FROM SupplierStats WHERE part_count > 5)
ORDER BY 
    r.r_name;
