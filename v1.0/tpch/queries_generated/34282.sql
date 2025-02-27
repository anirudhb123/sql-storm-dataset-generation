WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        0 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000.00
    
    UNION ALL
    
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE 
        sh.level < 5
),
TotalOrders AS (
    SELECT 
        o.o_custkey, 
        COUNT(o.o_orderkey) as total_order_count,
        SUM(o.o_totalprice) as total_revenue
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
P_Supply_Info AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
Part_Supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.total_avail_qty,
        ps.avg_supply_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.avg_supply_cost ASC) as supply_rank
    FROM 
        part p
    JOIN 
        P_Supply_Info ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    ph.s_name AS supplier_name,
    ph.level AS hierarchy_level,
    ti.total_order_count,
    ti.total_revenue,
    ps.p_name AS part_name,
    ps.total_avail_qty,
    ps.avg_supply_cost
FROM 
    SupplierHierarchy ph
LEFT JOIN 
    TotalOrders ti ON ph.s_suppkey = ti.o_custkey
LEFT JOIN 
    Part_Supplier ps ON ps.supply_rank = 1
WHERE 
    ph.level > 0 AND 
    (ti.total_revenue IS NULL OR ti.total_revenue > 10000) AND 
    ps.total_avail_qty IS NOT NULL
ORDER BY 
    ph.level, ti.total_revenue DESC;
