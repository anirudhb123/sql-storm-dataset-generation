WITH RecursiveCTE AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ls.l_extendedprice * (1 - ls.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem ls ON p.p_partkey = ls.l_partkey
    WHERE 
        ls.l_shipdate BETWEEN DATE '1994-01-01' AND DATE '1994-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopNations AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        COUNT(DISTINCT c.c_custkey) > 5
)
SELECT 
    r.r_name,
    COALESCE(n.customer_count, 0) AS top_nations_customer_count,
    CASE 
        WHEN r.r_name IS NULL THEN 'Unknown Region' 
        ELSE r.r_name 
    END AS region_alias,
    COALESCE(SUM(sr.total_supply_cost), 0) AS total_supply_cost,
    MAX(rc.total_revenue) AS highest_revenue,
    COUNT(DISTINCT rc.p_partkey) AS unique_parts_contributed
FROM 
    region r
LEFT JOIN 
    TopNations n ON r.r_name = n.n_name
LEFT JOIN 
    SupplierRevenue sr ON sr.total_supply_cost > 10000
LEFT JOIN 
    RecursiveCTE rc ON rc.rank = 1
GROUP BY 
    r.r_name, n.customer_count
ORDER BY 
    highest_revenue DESC
FETCH FIRST 10 ROWS ONLY;
