WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.*,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrders s
)
SELECT 
    r.r_name,
    ns.n_name,
    COALESCE(SUM(rs.total_revenue), 0) AS total_revenue,
    COALESCE(AVG(rs.total_revenue), 0) AS avg_revenue
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    RankedSuppliers rs ON ns.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey)
WHERE 
    ns.n_name IS NOT NULL
GROUP BY 
    r.r_name, ns.n_name
HAVING 
    SUM(rs.total_revenue) > 1000 
ORDER BY 
    r.r_name, avg_revenue DESC
LIMIT 10;