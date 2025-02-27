WITH RECURSIVE SeasonalSales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS spend_rank,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        c.c_custkey
),
TopSpenders AS (
    SELECT 
        c_nationkey,
        c_custkey,
        total_spent,
        order_count
    FROM 
        SeasonalSales
    WHERE 
        spend_rank <= 10
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighSupplyCost AS (
    SELECT 
        s.s_suppkey,
        CASE 
            WHEN total_supply_cost IS NULL THEN 0
            ELSE total_supply_cost
        END AS adjusted_supply_cost
    FROM 
        SupplierStats s
    WHERE 
        s.total_supply_cost > 1000
),
FinalReport AS (
    SELECT 
        ns.n_name,
        SUM(TotalRevenue) AS total_revenue,
        MAX(supply_cost) AS highest_supply_cost,
        COUNT(DISTINCT t.custkey) AS unique_customers,
        AVG(COALESCE(ty.adjusted_supply_cost, 0)) AS avg_supply_cost
    FROM 
        nation ns
    LEFT JOIN 
        TopSpenders t ON ns.n_nationkey = t.c_nationkey
    LEFT JOIN 
        HighSupplyCost ty ON t.custkey = ty.s_suppkey
    GROUP BY 
        ns.n_name
)
SELECT 
    fr.n_name,
    fr.total_revenue,
    fr.unique_customers,
    CASE 
        WHEN fr.highest_supply_cost > 5000 THEN 'High Supply Cost'
        ELSE 'Normal Supply Cost'
    END AS supply_cost_category
FROM 
    FinalReport fr
WHERE 
    fr.total_revenue IS NOT NULL
ORDER BY 
    fr.total_revenue DESC, fr.unique_customers ASC
WITH ROLLUP;
