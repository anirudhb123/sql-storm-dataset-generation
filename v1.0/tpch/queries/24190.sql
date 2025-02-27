
WITH regional_summary AS (
    SELECT 
        r.r_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY 
        o.o_orderkey
    HAVING 
        COUNT(l.l_orderkey) > 1
    AND 
        o.o_orderstatus IS NOT NULL
),
final_output AS (
    SELECT 
        rs.r_name,
        rs.total_supply_cost,
        os.total_revenue,
        os.revenue_rank
    FROM 
        regional_summary rs
    LEFT JOIN 
        order_summary os ON rs.supplier_count = os.revenue_rank
)
SELECT 
    r.r_name,
    COALESCE(f.total_supply_cost, 0) AS supply_cost_metrics,
    CASE 
        WHEN f.revenue_rank IS NULL THEN 'No Orders'
        ELSE 'Ranked Revenue ' || f.revenue_rank
    END AS revenue_status,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    STRING_AGG(DISTINCT c.c_name, ', ') AS affluent_customers
FROM 
    region r
LEFT JOIN 
    final_output f ON r.r_name = f.r_name
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
WHERE 
    r.r_name IS NOT NULL 
GROUP BY 
    r.r_name, f.total_supply_cost, f.revenue_rank
HAVING 
    COUNT(c.c_custkey) > 0
ORDER BY 
    supply_cost_metrics DESC, r.r_name ASC;
