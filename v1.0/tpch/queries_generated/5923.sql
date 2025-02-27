WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS status_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND 
        o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, o.o_orderpriority, c.c_name
),
TopSales AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.c_name,
        total_sales
    FROM 
        RankedOrders
    WHERE 
        status_rank <= 5
)
SELECT 
    ts.o_orderkey,
    ts.o_orderstatus,
    ts.o_totalprice,
    ts.o_orderdate,
    ts.o_orderpriority,
    ts.c_name,
    ts.total_sales
FROM 
    TopSales ts
JOIN 
    nation n ON ts.c_nationkey = n.n_nationkey 
WHERE 
    n.n_name IN ('USA', 'Canada')
ORDER BY 
    ts.o_orderdate DESC, ts.total_sales DESC;
