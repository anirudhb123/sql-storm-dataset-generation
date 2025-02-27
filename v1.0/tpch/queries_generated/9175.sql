WITH OrderSummaries AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        MAX(l.l_shipdate) AS max_ship_date,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        o.o_orderkey
),
RegionStats AS (
    SELECT 
        n.n_regionkey,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(cs.total_revenue) AS total_region_revenue,
        AVG(cs.avg_quantity) AS avg_quantity_per_order
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        OrderSummaries cs ON c.c_custkey IN (SELECT c.c_custkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE o.o_orderkey = cs.o_orderkey)
    GROUP BY 
        n.n_regionkey
),
FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        rs.customer_count,
        rs.total_region_revenue,
        rs.avg_quantity_per_order
    FROM 
        region r
    JOIN 
        RegionStats rs ON r.r_regionkey = rs.n_regionkey
)
SELECT 
    region_name,
    customer_count,
    total_region_revenue,
    avg_quantity_per_order,
    RANK() OVER (ORDER BY total_region_revenue DESC) AS revenue_rank
FROM 
    FinalReport
ORDER BY 
    revenue_rank;
