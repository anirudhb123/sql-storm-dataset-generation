WITH RevenuePerNation AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        n.n_name
),
TopNations AS (
    SELECT 
        nation_name,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RevenuePerNation
)
SELECT 
    t.nation_name,
    t.total_revenue,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS average_supplier_balance
FROM 
    TopNations t
JOIN 
    partsupp ps ON t.nation_name = (SELECT n.n_name FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = ps.ps_suppkey)
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    t.revenue_rank <= 5
GROUP BY 
    t.nation_name, t.total_revenue
ORDER BY 
    t.total_revenue DESC;