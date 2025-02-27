WITH revenue_summary AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate >= DATE '2022-01-01' AND l.l_shipdate < DATE '2023-01-01'
    GROUP BY 
        n.n_name
), ranked_revenue AS (
    SELECT 
        nation_name,
        total_revenue,
        order_count,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        revenue_summary
)
SELECT 
    r.nation_name,
    r.total_revenue,
    r.order_count,
    r.revenue_rank,
    p.p_brand,
    AVG(ps.ps_supplycost) AS average_supply_cost
FROM 
    ranked_revenue r
JOIN 
    partsupp ps ON r.nation_name = (SELECT n.n_name 
                                      FROM nation n 
                                      JOIN supplier s ON n.n_nationkey = s.s_nationkey
                                      WHERE s.s_suppkey = ps.ps_suppkey)
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    r.revenue_rank <= 10
GROUP BY 
    r.nation_name, r.total_revenue, r.order_count, r.revenue_rank, p.p_brand
ORDER BY 
    r.revenue_rank;
