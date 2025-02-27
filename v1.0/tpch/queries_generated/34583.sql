WITH RECURSIVE regional_summary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(s.s_acctbal) AS total_supply_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
    UNION ALL
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(s.s_acctbal) + rs.total_supply_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        regional_summary rs ON r.r_regionkey = rs.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    WHERE 
        rs.total_supply_balance IS NOT NULL
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    r.r_name AS region_name,
    CASE 
        WHEN SUM(COALESCE(l.l_quantity, 0)) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS part_activity_status,
    DENSE_RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice) DESC) AS revenue_rank
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    p.p_partkey, p.p_name, r.r_name
HAVING 
    SUM(l.l_extendedprice) > (SELECT AVG(total_supply_balance) FROM regional_summary WHERE r_name = r.r_name)
ORDER BY 
    region_name, revenue_rank;
