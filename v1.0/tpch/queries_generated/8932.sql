WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopSupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS supplier_value
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name
),
DetailedCustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(l.l_quantity) AS total_quantity,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.total_revenue,
    d.c_custkey,
    d.c_name,
    d.order_count,
    d.total_quantity,
    d.total_spent,
    t.ps_partkey,
    t.p_name,
    t.supplier_value
FROM 
    RankedOrders r
JOIN 
    DetailedCustomerOrders d ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate = r.o_orderdate)
JOIN 
    TopSupplierParts t ON t.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.total_revenue DESC, d.total_spent DESC;
