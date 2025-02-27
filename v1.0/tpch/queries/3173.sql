
WITH supplier_summary AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
), 
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    r.r_name,
    n.n_name,
    COALESCE(su.total_supply_cost, 0) AS total_cost,
    COALESCE(os.net_revenue, 0) AS revenue,
    CASE 
        WHEN os.revenue_rank IS NULL THEN 'No Revenue' 
        ELSE 'Revenue Generated' 
    END AS revenue_status
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier_summary su ON n.n_nationkey = su.s_nationkey
LEFT JOIN 
    order_summary os ON os.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
WHERE 
    (COALESCE(su.total_supply_cost, 0) > 100000 OR os.net_revenue IS NOT NULL)
ORDER BY 
    r.r_name, n.n_name;
