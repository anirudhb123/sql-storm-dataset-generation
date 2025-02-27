WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01'
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS number_of_customers,
    SUM(co.total_spent) AS total_revenue,
    AVG(co.total_spent) AS average_spent,
    COUNT(DISTINCT ts.ps_suppkey) AS top_supplier_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.ps_suppkey
JOIN 
    CustomerOrders co ON s.s_suppkey = co.c_custkey
WHERE 
    co.order_count > 5
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
