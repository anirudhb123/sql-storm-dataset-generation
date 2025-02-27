WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.total_available_quantity) AS total_quantity_per_nation,
        SUM(ss.total_cost) AS total_cost_per_nation,
        SUM(ss.parts_supplied) AS total_parts_supplied
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ns.n_name,
    ns.total_quantity_per_nation,
    ns.total_cost_per_nation,
    ns.total_parts_supplied,
    cos.c_name AS top_customer,
    cos.total_orders,
    cos.total_spent
FROM 
    NationStats ns
JOIN 
    (SELECT 
        c_nationkey, 
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rn,
        SUM(o.o_totalprice) AS total_spent
     FROM 
        customer c
     LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
     GROUP BY 
        c_nationkey, c.c_name
    ) cos ON ns.n_nationkey = cos.c_nationkey AND cos.rn = 1
ORDER BY 
    ns.total_quantity_per_nation DESC, ns.total_cost_per_nation DESC;
