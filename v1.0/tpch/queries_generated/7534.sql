WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_mktsegment
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
OrderSupplier AS (
    SELECT 
        o.o_orderkey,
        ps.ps_suppkey,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        HighValueOrders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        o.o_orderkey, ps.ps_suppkey
)
SELECT 
    r.r_name AS region_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS num_orders,
    SUM(o.total_revenue) AS total_revenue,
    AVG(ps.total_quantity) AS avg_quantity
FROM 
    RankedSuppliers s
JOIN 
    nation n ON s.supplier_nation = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    OrderSupplier o ON s.s_suppkey = o.ps_suppkey
GROUP BY 
    r.r_name, s.s_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_revenue DESC, num_orders DESC;
