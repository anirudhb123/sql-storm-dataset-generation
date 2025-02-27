WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_type, p.p_size
),
TopParts AS (
    SELECT 
        p_type,
        p_size,
        STRING_AGG(p_name, ', ') AS top_products
    FROM 
        RankedParts
    WHERE 
        revenue_rank <= 5
    GROUP BY 
        p_type, p_size
)
SELECT 
    r.r_name AS region_name,
    GROUP_CONCAT(tp.top_products) AS top_part_names
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    TopParts tp ON ps.ps_partkey = tp.p_partkey
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
