
WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS order_level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.order_level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE 
        oh.order_level < 5
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
RegionOrders AS (
    SELECT 
        r.r_name,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        r.r_name
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_type,
    COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS net_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    RANK() OVER (PARTITION BY p.p_type ORDER BY COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) DESC) AS revenue_rank
FROM 
    part p
LEFT JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierStats ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN 
    OrderHierarchy oh ON oh.o_orderkey = o.o_orderkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_type
HAVING 
    SUM(li.l_discount) > 0.1 OR COUNT(DISTINCT ps.ps_suppkey) > 2
ORDER BY 
    revenue_rank;
