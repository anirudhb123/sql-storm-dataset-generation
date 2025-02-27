WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        ts.s_suppkey,
        ts.s_name,
        ts.total_available_qty,
        ts.total_cost
    FROM 
        RankedSuppliers ts
    JOIN 
        nation n ON ts.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ts.rn <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        o.o_orderkey,
        COUNT(l.l_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey, o.o_orderkey
)
SELECT 
    to.region_name,
    to.nation_name,
    to.s_suppkey,
    to.s_name,
    co.c_custkey,
    co.c_name,
    co.order_count,
    to.total_available_qty,
    to.total_cost
FROM 
    TopSuppliers to
JOIN 
    CustomerOrders co ON to.s_nationkey = co.c_nationkey
ORDER BY 
    to.region_name, to.total_cost DESC, co.order_count DESC
LIMIT 50;
