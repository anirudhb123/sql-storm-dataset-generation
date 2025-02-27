WITH ranked_supply AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS supply_rank,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        partsupp ps
),
aggregated_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
customer_region AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        c.c_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.cust_name,
    cr.region_name,
    SUM(ao.total_revenue) AS total_order_revenue,
    COUNT(DISTINCT ao.o_orderkey) AS number_of_orders,
    COALESCE(SUM(rs.ps_supplycost), 0) AS total_supply_cost,
    CASE 
        WHEN SUM(ao.total_revenue) > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    customer_region cr
LEFT JOIN 
    aggregated_orders ao ON cr.c_custkey = ao.o_orderkey
LEFT JOIN 
    ranked_supply rs ON cr.cust_name = CONCAT('Supplier ', rs.ps_suppkey) OR rs.supply_rank = 1
WHERE 
    cr.c_acctbal IS NOT NULL
GROUP BY 
    cr.cust_name, cr.region_name
HAVING 
    COUNT(DISTINCT ao.o_orderkey) > 5
ORDER BY 
    total_order_revenue DESC;
