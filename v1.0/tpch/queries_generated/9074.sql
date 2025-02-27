WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopMonths AS (
    SELECT 
        DATE_TRUNC('month', o_orderdate) AS order_month,
        COUNT(DISTINCT o_orderkey) AS order_count
    FROM 
        RankedOrders
    WHERE 
        rank <= 5
    GROUP BY 
        DATE_TRUNC('month', o_orderdate)
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    tm.order_month,
    cd.c_name,
    cd.total_spent,
    tm.order_count
FROM 
    CustomerDetails cd
JOIN 
    TopMonths tm ON cd.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE DATE_TRUNC('month', o.o_orderdate) = tm.order_month)
ORDER BY 
    tm.order_month, cd.total_spent DESC;
