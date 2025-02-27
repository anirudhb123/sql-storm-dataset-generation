WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
),
RankedSales AS (
    SELECT 
        ts.p_partkey,
        ts.total_revenue,
        RANK() OVER (ORDER BY ts.total_revenue DESC) AS revenue_rank
    FROM 
        TotalSales ts
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        s.s_comment
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        sd.ps_partkey,
        sd.s_name,
        sd.s_nationkey,
        sd.s_acctbal,
        sd.s_comment,
        r.r_name
    FROM 
        SupplierDetails sd
    JOIN 
        nation n ON sd.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rs.revenue_rank,
    COUNT(*) AS supplier_count,
    AVG(ts.total_revenue) AS avg_revenue
FROM 
    RankedSales rs
JOIN 
    TopSuppliers ts ON rs.p_partkey = ts.ps_partkey
GROUP BY 
    rs.revenue_rank
ORDER BY 
    rs.revenue_rank;
