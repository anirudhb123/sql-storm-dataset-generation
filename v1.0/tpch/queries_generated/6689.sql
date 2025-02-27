WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopDailyRevenue AS (
    SELECT 
        orderdate,
        SUM(total_revenue) AS daily_revenue
    FROM (
        SELECT 
            o.o_orderdate AS orderdate,
            total_revenue 
        FROM 
            RankedOrders
        WHERE 
            rank <= 5
    ) AS TopOrders
    GROUP BY 
        orderdate
)
SELECT 
    d.orderdate,
    d.daily_revenue,
    r.r_name AS region_name,
    SUM(s.s_acctbal) AS total_supplier_balance
FROM 
    TopDailyRevenue d
JOIN 
    nation n ON n.n_nationkey IN (
        SELECT DISTINCT c.c_nationkey
        FROM customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
        WHERE o.o_orderdate = d.orderdate
    )
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
GROUP BY 
    d.orderdate, r.r_name
ORDER BY 
    d.orderdate, d.daily_revenue DESC;
