WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrdersSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COALESCE(SUM(o.o_totalprice), 0) > 100000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(ps.ps_availqty) AS max_avail_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 100
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.s_name,
    f.c_name,
    p.p_name,
    p.avg_supply_cost,
    o.total_revenue,
    RANK() OVER (ORDER BY o.total_revenue DESC) AS revenue_rank,
    CASE 
        WHEN p.max_avail_qty IS NULL THEN 'No Availability'
        ELSE CAST(p.max_avail_qty AS VARCHAR)
    END AS availability_status
FROM 
    RankedSuppliers r
JOIN 
    FilteredCustomers f ON r.s_suppkey = f.c_custkey
LEFT JOIN 
    PartDetails p ON r.part_count = (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = r.s_suppkey)
JOIN 
    OrdersSummary o ON f.c_custkey = o.o_custkey
WHERE 
    r.rank_within_nation = 1
    AND o.line_count > 5
    OR o.last_ship_date < '2023-01-01'
ORDER BY 
    revenue_rank ASC, 
    availability_status DESC;
