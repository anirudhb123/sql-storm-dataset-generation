WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
TotalSales AS (
    SELECT 
        l.l_suppkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_suppkey
),
NationPartPricing AS (
    SELECT 
        n.n_name, 
        p.p_name, 
        AVG(p.p_retailprice) AS avg_price
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name, p.p_name
)
SELECT 
    r.s_name,
    n.n_name,
    COALESCE(ts.total_revenue, 0) AS total_revenue,
    np.avg_price,
    CASE 
        WHEN ts.total_revenue IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    RankedSuppliers r
LEFT JOIN 
    TotalSales ts ON r.s_suppkey = ts.l_suppkey
JOIN 
    NationPartPricing np ON r.s_nationkey = np.n_name
WHERE 
    r.rank = 1
ORDER BY 
    total_revenue DESC, r.s_name;
