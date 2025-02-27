WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1994-01-01' AND DATE '1994-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        r.r_name,
        c.c_name,
        total_sales
    FROM 
        RankedOrders o
    JOIN 
        customer c ON c.c_custkey = (SELECT DISTINCT o_custkey FROM orders WHERE o_orderkey = o.o_orderkey)
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.sales_rank <= 10
)
SELECT 
    o_orderkey,
    o_orderdate,
    c_name,
    r_name,
    total_sales
FROM 
    TopOrders
ORDER BY 
    total_sales DESC;
