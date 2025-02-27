WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        DATEDIFF(CURDATE(), o.o_orderdate) AS days_since_order
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(l.l_orderkey) AS order_count,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_revenue_per_part
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        AVG(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT 
    r.r_name AS region_name,
    rs.s_name AS top_supplier,
    h.p_name AS high_value_part,
    h.order_count,
    h.avg_revenue_per_part,
    COUNT(ro.o_orderkey) AS recent_order_count,
    COALESCE(SUM(ro.o_totalprice), 0) AS total_recent_sales
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey AND rs.rank = 1
JOIN 
    HighValueParts h ON EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE ps.ps_partkey = h.p_partkey AND ps.ps_suppkey = rs.s_suppkey
    )
LEFT JOIN 
    RecentOrders ro ON ro.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = h.p_partkey
    )
GROUP BY 
    r.r_name, rs.s_name, h.p_name, h.order_count, h.avg_revenue_per_part
ORDER BY 
    total_recent_sales DESC, region_name, top_supplier;
