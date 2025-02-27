WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY YEAR(o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
Top10Revenue AS (
    SELECT 
        rr.o_orderkey, 
        rr.o_orderdate, 
        rr.c_name, 
        rr.total_revenue 
    FROM 
        RankedOrders rr
    WHERE 
        rr.revenue_rank <= 10
)
SELECT 
    t.o_orderkey, 
    t.o_orderdate, 
    t.c_name, 
    t.total_revenue,
    CONCAT('High Revenue Customer: ', t.c_name, ' | Order Date: ', DATE_FORMAT(t.o_orderdate, '%Y-%m-%d'), ' | Revenue: $', FORMAT(t.total_revenue, 2)) AS revenue_summary
FROM 
    Top10Revenue t
ORDER BY 
    t.total_revenue DESC;
