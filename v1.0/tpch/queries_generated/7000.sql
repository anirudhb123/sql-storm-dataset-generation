WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
TopCustomerNation AS (
    SELECT 
        c.c_nationkey,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS completed_orders,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    r.r_name,
    COUNT(ru.s_suppkey) AS supplier_count,
    AVG(t.total_value) AS avg_order_value,
    SUM(tc.completed_orders) AS total_completed_orders,
    SUM(tc.total_orders) AS total_orders
FROM 
    RankedSuppliers ru
JOIN 
    nation na ON ru.nation_name = na.n_name
JOIN 
    HighValueOrders t ON ru.s_suppkey = t.o_custkey
JOIN 
    TopCustomerNation tc ON na.n_nationkey = tc.c_nationkey
JOIN 
    region r ON na.n_regionkey = r.r_regionkey
WHERE 
    ru.rnk = 1
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
