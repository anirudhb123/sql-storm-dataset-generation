WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        l.l_shipdate >= DATE '1997-01-01' AND 
        l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
),
RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ts.total_revenue,
        RANK() OVER (ORDER BY ts.total_revenue DESC) AS revenue_rank
    FROM 
        TotalSales ts
    JOIN 
        part p ON ts.p_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    rs.p_name,
    rs.total_revenue,
    ts.s_name AS top_supplier,
    ts.total_supply_cost
FROM 
    RankedSales rs
JOIN 
    TopSuppliers ts ON rs.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
WHERE 
    rs.revenue_rank <= 10
ORDER BY 
    rs.total_revenue DESC;