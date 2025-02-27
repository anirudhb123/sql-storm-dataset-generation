WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
TotalOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_custkey
)
SELECT 
    c.c_name,
    c.c_address,
    c.c_phone,
    coalesce(t.order_count, 0) AS order_count,
    coalesce(t.total_revenue, 0) AS total_revenue,
    COUNT(rs.s_name) AS supplier_count,
    SUM(rs.total_cost) AS total_supplier_cost
FROM 
    customer c
LEFT JOIN 
    TotalOrders t ON c.c_custkey = t.o_custkey
LEFT JOIN 
    RankedSuppliers rs ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = c.c_nationkey)
GROUP BY 
    c.c_name, c.c_address, c.c_phone, t.order_count, t.total_revenue
ORDER BY 
    total_revenue DESC, customer_count DESC
LIMIT 10;
