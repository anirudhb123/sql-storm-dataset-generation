WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
NationRevenue AS (
    SELECT 
        n.n_name,
        SUM(co.total_revenue) AS total_nation_revenue
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        n.n_name
)
SELECT 
    sp.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(sp.ps_availqty) AS total_available_qty,
    nr.total_nation_revenue,
    nr.total_nation_revenue / NULLIF(SUM(sp.ps_availqty), 0) AS revenue_per_qty
FROM 
    SupplierParts sp
JOIN 
    NationRevenue nr ON sp.s_suppkey IN (
        SELECT s_suppkey 
        FROM supplier s 
        WHERE s.s_nationkey IN (
            SELECT n_nationkey 
            FROM nation n
            WHERE n.n_name = 'USA' -- Example filter for a specific nation
        )
    )
GROUP BY 
    sp.s_name, p.p_name, nr.total_nation_revenue
ORDER BY 
    revenue_per_qty DESC
LIMIT 10;
