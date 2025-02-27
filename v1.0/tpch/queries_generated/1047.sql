WITH CTE_SupplierCosts AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    GROUP BY 
        ps.s_suppkey
),
CTE_LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_item_count,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > '2022-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(COALESCE(l.total_revenue, 0)) AS total_revenue_generated,
    SUM(s.total_supply_cost) AS total_supply_costs
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    CTE_LineItemSummary l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    CTE_SupplierCosts s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey) LIMIT 1)
GROUP BY 
    n.n_name, r.r_name
HAVING 
    SUM(COALESCE(l.total_revenue, 0)) > 100000
ORDER BY 
    total_revenue_generated DESC, unique_customers DESC;
