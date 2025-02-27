WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopRevenueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        total_revenue,
        revenue_rank
    FROM 
        RankedOrders o
    WHERE 
        revenue_rank <= 10
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_address,
    SUM(TO_NUMBER(T.total_revenue, '999999999.99')) AS total_customer_revenue,
    COUNT(DISTINCT T.o_orderkey) AS order_count
FROM 
    customer c
JOIN 
    TopRevenueOrders T ON c.c_custkey = (
        SELECT o.o_custkey 
        FROM orders o 
        WHERE o.o_orderkey = T.o_orderkey
    )
GROUP BY 
    c.c_custkey, c.c_name, c.c_address
ORDER BY 
    total_customer_revenue DESC
LIMIT 5;
