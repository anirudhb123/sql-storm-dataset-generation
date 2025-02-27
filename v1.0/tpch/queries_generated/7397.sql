WITH RegionSummary AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
FinalReport AS (
    SELECT 
        rs.region_name,
        cos.order_count,
        cos.total_order_value,
        rs.supplier_count,
        rs.total_supply_cost
    FROM 
        RegionSummary rs
    LEFT JOIN 
        CustomerOrderSummary cos ON rs.region_name = 
        (SELECT r_name FROM region r 
         JOIN nation n ON r.r_regionkey = n.n_regionkey 
         WHERE n.n_nationkey = cos.c_nationkey)
)
SELECT 
    fr.region_name,
    fr.order_count,
    fr.total_order_value,
    fr.supplier_count,
    fr.total_supply_cost,
    (fr.total_order_value / NULLIF(fr.order_count, 0)) AS avg_order_value,
    (fr.total_supply_cost / NULLIF(fr.supplier_count, 0)) AS avg_supply_cost_per_supplier
FROM 
    FinalReport fr
ORDER BY 
    fr.region_name;
