WITH total_sales AS (
    SELECT 
        l.partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' 
        AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        l.partkey
),
supplier_info AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ts.total_revenue, 0) AS total_revenue,
        RANK() OVER (ORDER BY COALESCE(ts.total_revenue, 0) DESC) AS revenue_rank
    FROM 
        part p
    LEFT JOIN 
        total_sales ts ON p.p_partkey = ts.partkey
),
part_supplier_info AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.total_revenue,
        CASE 
            WHEN si.s_suppkey IS NOT NULL THEN 'Supplied' 
            ELSE 'Not Supplied' 
        END AS supplier_status
    FROM 
        ranked_parts rp
    LEFT JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier_info si ON ps.ps_suppkey = si.s_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.total_revenue,
    p.supplier_status,
    CASE 
        WHEN p.total_revenue > 100000 THEN 'High Revenue'
        WHEN p.total_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    part_supplier_info p
WHERE 
    p.revenue_rank <= 10
ORDER BY 
    p.total_revenue DESC;
