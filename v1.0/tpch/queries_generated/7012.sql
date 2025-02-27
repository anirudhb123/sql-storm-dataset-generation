WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
RankedSales AS (
    SELECT 
        ts.p_partkey,
        ts.p_name,
        ts.total_revenue,
        RANK() OVER (ORDER BY ts.total_revenue DESC) AS revenue_rank
    FROM 
        TotalSales ts
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 1
),
FinalResults AS (
    SELECT 
        rs.revenue_rank,
        rs.p_name,
        ts.total_revenue,
        ts.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        RankedSales rs
    JOIN 
        partsupp ps ON rs.p_partkey = ps.ps_partkey
    JOIN 
        TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
    WHERE 
        rs.revenue_rank <= 10
    GROUP BY 
        rs.revenue_rank, rs.p_name, ts.total_revenue, ts.p_partkey
)
SELECT 
    fr.revenue_rank,
    fr.p_name,
    fr.total_revenue,
    fr.supplier_count
FROM 
    FinalResults fr
ORDER BY 
    fr.revenue_rank;
