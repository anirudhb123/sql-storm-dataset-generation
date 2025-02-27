WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal >= (
            SELECT AVG(c2.c_acctbal) 
            FROM customer c2
        )
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        li.l_quantity,
        li.l_extendedprice,
        li.l_discount,
        li.l_tax,
        s.s_name,
        n.n_name
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    JOIN 
        supplier s ON li.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    r.r_name,
    RANK() OVER (ORDER BY SUM(od.l_extendedprice * (1 - od.l_discount))) AS revenue_rank,
    COUNT(DISTINCT c.c_custkey) AS number_of_customers,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_revenue
FROM 
    OrderDetails od
JOIN 
    HighValueCustomers c ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
JOIN 
    nation n ON od.n_name = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
HAVING 
    total_revenue > 1000000
ORDER BY 
    total_revenue DESC;
