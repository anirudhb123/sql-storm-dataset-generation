WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sr.total_revenue,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierRevenue sr
    JOIN 
        supplier s ON sr.s_suppkey = s.s_suppkey
    WHERE 
        sr.total_revenue IS NOT NULL
),
NationStats AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.total_revenue,
    n.n_name,
    n.supplier_count,
    n.avg_account_balance,
    COALESCE(t.revenue_rank, 'NA') AS revenue_rank_status
FROM 
    TopSuppliers t
FULL OUTER JOIN 
    NationStats n ON t.s_suppkey = n.supplier_count
WHERE 
    n.avg_account_balance > 1000 OR t.total_revenue > 10000
ORDER BY 
    n.n_name, t.total_revenue DESC;
