WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
    ORDER BY 
        supplier_cost DESC
    LIMIT 10
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUM(o.total_revenue) AS total_nation_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT ts.ps_suppkey) AS top_suppliers_count
FROM 
    RankedOrders o
JOIN 
    customer c ON o.o_orderkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    TopSuppliers ts ON c.c_nationkey = (
        SELECT n.n_nationkey 
        FROM supplier s 
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_brand = 'Brand#54'
        LIMIT 1
    )
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 100
ORDER BY 
    total_nation_revenue DESC;