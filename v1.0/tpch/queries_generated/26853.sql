WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_name,
        rs.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY rs.s_acctbal DESC) AS rank_by_region
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
),
SelectedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_type LIKE '%metal%'
),
AggregatedData AS (
    SELECT 
        ts.r_name,
        sp.p_name,
        SUM(sp.ps_availqty) AS total_available_qty,
        SUM(sp.ps_supplycost) AS total_supply_cost
    FROM 
        TopSuppliers ts
    LEFT JOIN 
        SelectedParts sp ON ts.s_name = (SELECT s.s_name FROM supplier s WHERE s.s_suppkey = ts.s_suppkey)
    GROUP BY 
        ts.r_name, sp.p_name
)
SELECT 
    ad.r_name,
    ad.p_name,
    ad.total_available_qty,
    ad.total_supply_cost,
    CASE 
        WHEN ad.total_supply_cost > 1000 THEN 'High Cost'
        WHEN ad.total_supply_cost BETWEEN 500 AND 1000 THEN 'Medium Cost'
        ELSE 'Low Cost'
    END AS cost_category
FROM 
    AggregatedData ad
ORDER BY 
    ad.r_name, ad.total_supply_cost DESC;
