WITH PartSupplierSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
NationRegionSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    nrs.region_name,
    ps.p_name,
    COALESCE(cos.total_orders, 0) AS orders_count,
    COALESCE(cos.total_spent, 0) AS spent,
    pss.total_available,
    pss.total_supply_cost,
    CASE 
        WHEN COALESCE(cos.total_spent, 0) > 0 THEN (pss.total_supply_cost / NULLIF(cos.total_spent, 0)) 
        ELSE NULL 
    END AS supply_cost_ratio
FROM 
    PartSupplierSummary pss
JOIN 
    NationRegionSummary nrs ON nrs.n_nationkey = (SELECT s.nationkey FROM supplier s WHERE s.s_suppkey = (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = pss.p_partkey LIMIT 1))
LEFT JOIN 
    CustomerOrderSummary cos ON cos.total_orders > 0
ORDER BY 
    nrs.region_name, pss.total_available DESC;
