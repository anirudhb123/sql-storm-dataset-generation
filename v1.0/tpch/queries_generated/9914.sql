WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS status_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        total_cost > 100000
),
CustomerNations AS (
    SELECT 
        c.c_custkey,
        n.n_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        n.n_name IN (SELECT DISTINCT n_name FROM nation WHERE r_regionkey = 1)
    GROUP BY 
        c.c_custkey, n.n_name
)
SELECT 
    r.o_orderkey,
    r.o_orderstatus,
    ts.ps_suppkey,
    cn.n_name,
    cn.total_spent,
    r.total_revenue
FROM 
    RankedOrders r
JOIN 
    TopSuppliers ts ON r.o_orderkey % 100 = ts.ps_suppkey  -- Example join condition for demonstration
JOIN 
    CustomerNations cn ON r.o_orderkey % 50 = cn.c_custkey  -- Example join condition for demonstration
WHERE 
    r.status_rank <= 10
ORDER BY 
    r.o_orderstatus, ts.total_cost DESC;
