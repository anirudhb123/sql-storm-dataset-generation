WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, c.c_mktsegment
),
TopRevenue AS (
    SELECT 
        m.c_mktsegment,
        SUM(r.revenue) AS total_revenue
    FROM 
        RankedOrders r
    JOIN 
        customer m ON r.o_orderkey IN (
            SELECT o.o_orderkey 
            FROM orders o 
            JOIN customer c ON o.o_custkey = c.c_custkey
            WHERE c.c_mktsegment = m.c_mktsegment
        )
    WHERE 
        r.rank <= 10
    GROUP BY 
        m.c_mktsegment
)
SELECT 
    t.c_mktsegment,
    t.total_revenue,
    r.r_name 
FROM 
    TopRevenue t
JOIN 
    nation n ON n.n_nationkey = (
        SELECT 
            s.s_nationkey 
        FROM 
            supplier s 
        WHERE 
            s.s_suppkey IN (
                SELECT 
                    ps.ps_suppkey 
                FROM 
                    partsupp ps 
                JOIN 
                    part p ON ps.ps_partkey = p.p_partkey 
                WHERE 
                    p.p_size > 20
            )
        LIMIT 1
    )
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
ORDER BY 
    t.total_revenue DESC;