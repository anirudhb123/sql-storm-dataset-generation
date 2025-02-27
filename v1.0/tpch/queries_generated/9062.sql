WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS rank_per_nation
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
TopOrders AS (
    SELECT 
        ro.* 
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank_per_nation <= 10
)
SELECT 
    to.customer_name,
    to.nation_name,
    COUNT(to.o_orderkey) AS number_of_orders,
    SUM(to.o_totalprice) AS total_revenue
FROM 
    TopOrders to
GROUP BY 
    to.customer_name, to.nation_name
ORDER BY 
    total_revenue DESC
LIMIT 100;
