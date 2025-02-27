WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartMetrics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderLineDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)

SELECT 
    co.c_custkey,
    co.c_name,
    COALESCE(co.total_spent, 0) AS total_spent,
    COALESCE(co.order_count, 0) AS order_count,
    spm.total_available_quantity,
    spm.avg_supply_cost,
    ord.total_revenue,
    ord.line_count
FROM 
    CustomerOrderSummary co
LEFT JOIN 
    SupplierPartMetrics spm ON co.c_custkey = spm.s_suppkey
LEFT JOIN 
    OrderLineDetails ord ON co.c_custkey = ord.o_orderkey
WHERE 
    COALESCE(co.total_spent, 0) > 1000 
    OR (spm.avg_supply_cost IS NOT NULL AND spm.avg_supply_cost < 50)
ORDER BY 
    total_spent DESC, total_available_quantity DESC;

WITH RECURSIVE RegionHierarchy AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        CAST(NULL AS char(25)) AS parent_region
    FROM 
        region r
    UNION ALL
    SELECT 
        r.r_regionkey,
        r.r_name,
        rh.r_name AS parent_region
    FROM 
        region r
    JOIN 
        RegionHierarchy rh ON r.r_regionkey = rh.r_regionkey
)
SELECT 
    rh.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(s.s_acctbal) AS total_supplier_balance
FROM 
    RegionHierarchy rh
LEFT JOIN 
    nation n ON n.n_regionkey = rh.r_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
GROUP BY 
    rh.r_name
HAVING 
    nation_count > 2
ORDER BY 
    total_supplier_balance DESC;
