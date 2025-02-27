WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
RegionTotals AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(total_supply_cost) AS total_cost_by_region
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.supplier_rank = 1
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    rt.r_name,
    rt.total_cost_by_region,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(c.c_acctbal) AS average_account_balance
FROM 
    RegionTotals rt
JOIN 
    customer c ON c.c_nationkey IN (SELECT n.n_nationkey FROM nation n JOIN region r ON n.n_regionkey = r.r_regionkey WHERE r.r_name = rt.r_name)
GROUP BY 
    rt.r_name, rt.total_cost_by_region
ORDER BY 
    rt.total_cost_by_region DESC, total_customers DESC;
