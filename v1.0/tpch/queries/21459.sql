WITH Regional_Supplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
High_Value_Suppliers AS (
    SELECT 
        r.region_name,
        rs.s_suppkey,
        rs.s_name,
        rs.total_available_quantity,
        rs.total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY r.region_name ORDER BY rs.total_supply_cost DESC) AS rank
    FROM 
        (SELECT r.r_name AS region_name, r.r_regionkey 
         FROM region r 
         WHERE r.r_comment IS NOT NULL AND r.r_name NOT LIKE '%Unknown%') r
    JOIN 
        Regional_Supplier rs ON rs.nation_name = (SELECT n.n_name 
                                                   FROM nation n 
                                                   WHERE n.n_regionkey = r.r_regionkey 
                                                   LIMIT 1)
)
SELECT 
    hvs.region_name, 
    hvs.s_name, 
    hvs.total_available_quantity,
    hvs.total_supply_cost,
    CASE 
        WHEN hvs.rank <= 10 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS supplier_rank_category
FROM 
    High_Value_Suppliers hvs
WHERE 
    hvs.total_supply_cost > (SELECT AVG(total_supply_cost) 
                              FROM High_Value_Suppliers)
    OR hvs.total_available_quantity IS NULL
ORDER BY 
    hvs.region_name, hvs.total_supply_cost DESC;
