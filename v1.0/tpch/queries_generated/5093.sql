WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    RANK() OVER (ORDER BY r.total_revenue DESC) AS revenue_rank,
    r.o_orderkey,
    r.o_orderdate,
    r.total_revenue,
    tc.c_custkey,
    tc.c_name,
    spi.s_name AS supplier_name,
    spi.p_name AS part_name,
    spi.ps_supplycost,
    spi.ps_availqty
FROM 
    RankedOrders r
JOIN 
    TopCustomers tc ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_custkey)
JOIN 
    SupplierPartInfo spi ON spi.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
WHERE 
    r.rn = 1
ORDER BY 
    revenue_rank, total_revenue DESC;
