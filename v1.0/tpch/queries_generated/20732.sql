WITH RecursiveCTE AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_suppkey = l.l_suppkey AND l.l_returnflag = 'N'
    WHERE 
        p.p_size < 20 AND p.p_container IS NOT NULL
    GROUP BY 
        p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
),
FilteredCTE AS (
    SELECT 
        *,
        CASE 
            WHEN total_revenue > 1000 THEN 'High'
            WHEN total_revenue BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS revenue_category
    FROM 
        RecursiveCTE
    WHERE 
        rn = 1
),
FinalResult AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_name) AS nation_count,
        SUM(CASE 
            WHEN s.s_acctbal IS NULL THEN 0 
            ELSE s.s_acctbal 
        END) AS total_acct_bal,
        AVG(f.total_revenue) AS avg_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        FilteredCTE f ON s.s_suppkey = f.ps_partkey
    GROUP BY 
        r.r_name
)
SELECT 
    r_name,
    nation_count,
    total_acct_bal,
    avg_revenue,
    CASE 
        WHEN avg_revenue IS NULL THEN 'No Revenue'
        WHEN avg_revenue < 1000 THEN 'Underperforming'
        ELSE 'Performing Well'
    END AS performance
FROM 
    FinalResult
WHERE 
    total_acct_bal > (
        SELECT 
            AVG(total_acct_bal) 
        FROM 
            FinalResult
        WHERE 
            nation_count > 1
    )
ORDER BY 
    r_name DESC;
