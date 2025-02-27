WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
TopOrders AS (
    SELECT 
        c.n_name AS nation,
        COUNT(*) AS order_count,
        SUM(revenue) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        nation c ON c.n_nationkey = (
            SELECT n_nationkey 
            FROM supplier s 
            WHERE s.s_suppkey = ro.o_orderkey 
            LIMIT 1
        )
    WHERE 
        order_rank <= 10
    GROUP BY 
        c.n_name
)
SELECT 
    nation,
    order_count,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM 
    TopOrders
ORDER BY 
    revenue_rank;
