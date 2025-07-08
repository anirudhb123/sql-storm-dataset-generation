WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE 
        oh.level < 5
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    p.p_name,
    p.p_partkey,
    r.r_name AS region,
    COALESCE(c.c_name, 'Unknown') AS customer_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    (SELECT COUNT(DISTINCT l.l_orderkey) FROM lineitem l WHERE l.l_partkey = p.p_partkey) AS order_count,
    COUNT(DISTINCT oh.o_orderkey) AS order_hierarchy_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    FilteredCustomers c ON c.c_custkey = s.s_nationkey
LEFT JOIN 
    OrderHierarchy oh ON oh.o_orderkey = s.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, r.r_name, c.c_name, s.s_name
HAVING 
    SUM(ps.ps_availqty) > 0 OR COUNT(DISTINCT oh.o_orderkey) > 0
ORDER BY 
    total_available_quantity DESC, avg_supply_cost DESC;