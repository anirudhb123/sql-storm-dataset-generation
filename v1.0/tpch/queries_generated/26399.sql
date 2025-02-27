WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    r_s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COUNT(o.o_orderkey) AS order_count,
    SUM(o.o_totalprice) AS total_revenue,
    STRING_AGG(CONCAT('Order ', o.o_orderkey, ' on ', o.o_orderdate)) AS order_details
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    RankedSuppliers r_s ON n.n_nationkey = r_s.s_nationkey AND r_s.rank <= 3
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
GROUP BY 
    r.r_name, n.n_name, r_s.s_name, c.c_name
ORDER BY 
    total_revenue DESC;
