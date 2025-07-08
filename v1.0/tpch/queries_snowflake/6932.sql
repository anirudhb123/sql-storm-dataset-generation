
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 

TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        RankedSuppliers s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.rnk <= 5
),

RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
)

SELECT 
    c.c_custkey,
    c.c_name,
    c.c_acctbal,
    SUM(t.ps_supplycost) AS total_cost,
    COUNT(DISTINCT r.o_orderkey) AS orders_count,
    SUM(r.total_revenue) AS total_revenue
FROM 
    customer c
LEFT JOIN 
    RecentOrders r ON c.c_custkey = r.o_custkey
LEFT JOIN 
    TopSuppliers t ON r.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
        WHERE ps.ps_suppkey = t.s_suppkey
    )
GROUP BY 
    c.c_custkey, c.c_name, c.c_acctbal
ORDER BY 
    total_cost DESC, orders_count DESC
LIMIT 100;
