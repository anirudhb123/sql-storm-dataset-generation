WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
TopCustomers AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        SUM(o.o_totalprice) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        RankedOrders o
    JOIN 
        nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
    JOIN 
        region r ON r.r_regionkey = n.n_regionkey
    WHERE 
        o.order_rank <= 5
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    region,
    nation,
    total_revenue,
    order_count,
    DENSE_RANK() OVER (PARTITION BY region ORDER BY total_revenue DESC) AS revenue_rank
FROM 
    TopCustomers
ORDER BY 
    region, revenue_rank;
