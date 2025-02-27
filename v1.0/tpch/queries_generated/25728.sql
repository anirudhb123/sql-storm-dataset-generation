WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
        STRING_AGG(DISTINCT r.r_name, ', ') AS regions,
        COUNT(DISTINCT ps.ps_partkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand
),
FullDetails AS (
    SELECT 
        sa.p_partkey,
        sa.p_name,
        sa.p_mfgr,
        sa.p_brand,
        sa.suppliers,
        sa.regions,
        sa.supplier_count,
        CASE 
            WHEN sa.supplier_count > 5 THEN 'Highly Supplied'
            WHEN sa.supplier_count BETWEEN 3 AND 5 THEN 'Moderately Supplied'
            ELSE 'Less Supplied'
        END AS supply_category
    FROM StringAggregation sa
)
SELECT 
    p.p_partkey,
    p.p_name, 
    p.p_brand, 
    p.p_mfgr, 
    p.p_retailprice, 
    fd.suppliers, 
    fd.regions, 
    fd.supplier_count, 
    fd.supply_category,
    REPLACE(REPLACE(fd.suppliers, ',', '; '), ' ', '-') AS formatted_suppliers
FROM part p
JOIN FullDetails fd ON p.p_partkey = fd.p_partkey
WHERE p.p_size BETWEEN 10 AND 20
ORDER BY fd.supplier_count DESC, p.p_partkey;
