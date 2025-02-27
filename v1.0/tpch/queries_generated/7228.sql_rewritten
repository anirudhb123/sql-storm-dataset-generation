WITH RegionalSummary AS (
    SELECT 
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        r.r_name
), CustomerSummary AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
)
SELECT 
    rs.region_name,
    rs.total_supply_cost,
    rs.total_orders,
    rs.total_revenue,
    cs.nation_name,
    cs.total_customers,
    cs.total_order_value
FROM 
    RegionalSummary rs
JOIN 
    CustomerSummary cs ON rs.region_name = (SELECT r_name FROM region WHERE r_regionkey = (SELECT n_regionkey FROM nation WHERE n_name = cs.nation_name))
ORDER BY 
    rs.total_revenue DESC, cs.total_order_value DESC;