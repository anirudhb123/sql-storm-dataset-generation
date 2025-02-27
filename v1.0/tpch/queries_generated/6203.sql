WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
HighValueSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_name,
        rs.total_supply_value
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
),
RevenuePerCustomer AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    hs.region_name,
    hs.nation_name,
    hs.s_name,
    hp.total_revenue,
    hp.total_revenue / hs.total_supply_value AS revenue_to_supply_ratio
FROM 
    HighValueSuppliers hs
JOIN 
    RevenuePerCustomer hp ON hs.s_name = hp.c_name
WHERE 
    hp.total_revenue IS NOT NULL
ORDER BY 
    hs.region_name, hs.nation_name, revenue_to_supply_ratio DESC;
