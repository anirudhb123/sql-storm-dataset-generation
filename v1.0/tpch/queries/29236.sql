WITH SupplierProducts AS (
    SELECT 
        s.s_name AS supplier_name,
        COUNT(DISTINCT ps.ps_partkey) AS product_count,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),

NationProductCounts AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_product_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name
)

SELECT 
    sp.supplier_name,
    sp.product_count,
    sp.total_available_qty,
    sp.average_supply_cost,
    npc.nation_name,
    npc.distinct_product_count
FROM 
    SupplierProducts sp
JOIN 
    nation n ON EXISTS (
        SELECT 1 
        FROM supplier s 
        WHERE s.s_name = sp.supplier_name AND s.s_nationkey = n.n_nationkey
    )
JOIN 
    NationProductCounts npc ON npc.nation_name = n.n_name
WHERE 
    sp.product_count > 5
ORDER BY 
    sp.total_available_qty DESC, 
    npc.distinct_product_count ASC;
