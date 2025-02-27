WITH total_sales AS (
    SELECT 
        l_partkey, 
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1995-01-01' AND l_shipdate < DATE '1996-01-01'
    GROUP BY 
        l_partkey
),
supplier_info AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
nation_sales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ts.total_revenue) AS revenue
    FROM 
        nation n
    JOIN 
        supplier_info si ON n.n_nationkey = si.s_nationkey
    JOIN 
        total_sales ts ON ts.l_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = si.s_suppkey LIMIT 1)
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    ns.revenue,
    si.total_supply_cost
FROM 
    nation_sales ns
JOIN 
    supplier_info si ON ns.n_nationkey = si.s_nationkey
ORDER BY 
    ns.revenue DESC, si.total_supply_cost ASC
LIMIT 10;
