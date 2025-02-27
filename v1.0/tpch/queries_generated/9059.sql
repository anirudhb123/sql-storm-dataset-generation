WITH RevenueByNation AS (
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
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        n.n_name
),
TopNations AS (
    SELECT 
        nation_name,
        total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rank
    FROM 
        RevenueByNation
)
SELECT 
    tn.nation_name,
    tn.total_revenue,
    CONCAT('This nation generated revenue of $', TO_CHAR(tn.total_revenue, 'FM999,999,999.00')) AS revenue_statement
FROM 
    TopNations tn
WHERE 
    tn.rank <= 5
ORDER BY 
    tn.total_revenue DESC;
