WITH SupplierOrderInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
RankedSuppliers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrderInfo
)
SELECT 
    r.nation_name,
    rs.s_name,
    rs.total_revenue,
    rs.order_count
FROM 
    RankedSuppliers rs
JOIN 
    (SELECT DISTINCT n_name FROM nation) r ON rs.nation_name = r.n_name
WHERE 
    rs.revenue_rank <= 5
ORDER BY 
    r.nation_name, rs.total_revenue DESC;
