WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_name,
        SUM(total_revenue) AS total_revenue
    FROM 
        RankedOrders
    JOIN 
        customer c ON RankedOrders.c_name = c.c_name
    GROUP BY 
        c.c_name
    ORDER BY 
        total_revenue DESC
    LIMIT 10
)
SELECT 
    p.p_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    rc.region_name
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region rc ON n.n_regionkey = rc.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_type LIKE '%BRASS%'
    AND EXISTS (SELECT 1 FROM TopCustomers tc WHERE tc.c_name = s.s_name)
GROUP BY 
    p.p_name, rc.region_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_sales DESC;
