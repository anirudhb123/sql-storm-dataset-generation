WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT 
    r.r_name,
    SUM(co.o_totalprice) AS total_revenue,
    AVG(co.item_count) AS average_items_per_order,
    COUNT(DISTINCT rs.s_name) AS unique_suppliers,
    STRING_AGG(DISTINCT rs.s_name, ', ') AS supplier_names
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
JOIN 
    CustomerOrders co ON co.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = rs.s_suppkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
